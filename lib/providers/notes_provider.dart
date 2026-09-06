import 'dart:async';
import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_sync_service.dart';

enum SyncStatus { idle, syncing, synced, offline, error }

class NotesProvider extends ChangeNotifier {
  final LocalStorageService _localStorage = LocalStorageService();
  final FirestoreSyncService _firestoreSync = FirestoreSyncService();

  List<NoteModel> _notes = [];
  String _searchQuery = '';
  String? _selectedTag;
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _currentUserId;
  StreamSubscription<List<NoteModel>>? _firestoreSubscription;

  List<NoteModel> get allNotes => _notes;
  SyncStatus get syncStatus => _syncStatus;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;

  NotesProvider() {
    _init();
  }

  Future<void> _init() async {
    // 1. Tải dữ liệu từ bộ nhớ máy ngay lập tức (Offline-First, không cần chờ mạng)
    _notes = await _localStorage.loadNotes();
    notifyListeners();
  }

  /// Cập nhật User ID và thiết lập lắng nghe đồng bộ từ Firebase
  void updateUserId(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _firestoreSubscription?.cancel();

    if (userId != null && userId.isNotEmpty) {
      _startCloudSync(userId);
    }
  }

  /// Bắt đầu luồng đồng bộ thời gian thực từ Cloud Firestore
  void _startCloudSync(String userId) {
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      _firestoreSubscription = _firestoreSync.streamNotes(userId).listen(
        (cloudNotes) async {
          _mergeCloudNotes(cloudNotes);
          _syncStatus = SyncStatus.synced;
          notifyListeners();
        },
        onError: (error) {
          _syncStatus = SyncStatus.offline;
          notifyListeners();
        },
      );
    } catch (_) {
      _syncStatus = SyncStatus.offline;
      notifyListeners();
    }
  }

  /// Hợp nhất dữ liệu đám mây và dữ liệu cục bộ dựa trên timestamp (Last-Write-Wins)
  void _mergeCloudNotes(List<NoteModel> cloudNotes) {
    final Map<String, NoteModel> noteMap = {for (var n in _notes) n.id: n};

    for (final cloudNote in cloudNotes) {
      if (!noteMap.containsKey(cloudNote.id)) {
        noteMap[cloudNote.id] = cloudNote;
      } else {
        final localNote = noteMap[cloudNote.id]!;
        // Nếu bản ghi trên đám mây mới hơn bản ghi trong máy thì cập nhật
        if (cloudNote.updatedAt.isAfter(localNote.updatedAt)) {
          noteMap[cloudNote.id] = cloudNote;
        }
      }
    }

    _notes = noteMap.values.toList();
    // Sắp xếp ghi chú theo thời gian cập nhật mới nhất lên đầu
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _localStorage.saveNotes(_notes);
  }

  // --- Bộ lọc & Tìm kiếm ---

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  /// Danh sách tất cả các nhãn (Tags) hiện có
  Set<String> get allTags {
    final Set<String> tags = {};
    for (final note in _notes) {
      if (!note.isDeleted) {
        tags.addAll(note.tags);
      }
    }
    return tags;
  }

  /// Các ghi chú đang hoạt động (không bị xóa, không bị lưu trữ) sau khi lọc
  List<NoteModel> get filteredActiveNotes {
    return _notes.where((note) {
      if (note.isDeleted || note.isArchived) return false;

      // Lọc theo tag
      if (_selectedTag != null && !note.tags.contains(_selectedTag)) {
        return false;
      }

      // Lọc theo từ khóa tìm kiếm
      if (_searchQuery.isNotEmpty) {
        final matchesTitle = note.title.toLowerCase().contains(_searchQuery);
        final matchesContent = note.content.toLowerCase().contains(_searchQuery);
        final matchesTag = note.tags.any((t) => t.toLowerCase().contains(_searchQuery));
        final matchesChecklist = note.checklist.any((item) => item.text.toLowerCase().contains(_searchQuery));
        return matchesTitle || matchesContent || matchesTag || matchesChecklist;
      }

      return true;
    }).toList();
  }

  List<NoteModel> get pinnedNotes =>
      filteredActiveNotes.where((note) => note.isPinned).toList();

  List<NoteModel> get unpinnedNotes =>
      filteredActiveNotes.where((note) => !note.isPinned).toList();

  List<NoteModel> get archivedNotes =>
      _notes.where((note) => note.isArchived && !note.isDeleted).toList();

  List<NoteModel> get trashNotes =>
      _notes.where((note) => note.isDeleted).toList();

  // --- Thao tác CRUD (Create, Read, Update, Delete) ---

  /// Thêm hoặc Cập nhật ghi chú
  Future<void> saveNote(NoteModel note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    final updatedNote = note.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    if (index >= 0) {
      _notes[index] = updatedNote;
    } else {
      _notes.insert(0, updatedNote);
    }

    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();

    // 1. Lưu vào bộ nhớ máy ngay lập tức (Offline-first)
    await _localStorage.saveNotes(_notes);

    // 2. Đẩy lên Firebase nếu đã đăng nhập
    if (_currentUserId != null) {
      _syncStatus = SyncStatus.syncing;
      notifyListeners();
      try {
        await _firestoreSync.saveNoteToCloud(_currentUserId!, updatedNote);
        _syncStatus = SyncStatus.synced;
      } catch (_) {
        _syncStatus = SyncStatus.offline;
        await _localStorage.markForSync(updatedNote.id);
      }
      notifyListeners();
    }
  }

  /// Bật / Tắt trạng thái Ghim ghi chú
  Future<void> togglePin(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      final note = _notes[index];
      await saveNote(note.copyWith(isPinned: !note.isPinned));
    }
  }

  /// Chuyển ghi chú vào thùng rác (Soft Delete)
  Future<void> moveToTrash(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      final note = _notes[index];
      await saveNote(note.copyWith(isDeleted: true, isPinned: false));
    }
  }

  /// Khôi phục ghi chú từ thùng rác
  Future<void> restoreFromTrash(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      final note = _notes[index];
      await saveNote(note.copyWith(isDeleted: false));
    }
  }

  /// Xóa vĩnh viễn ghi chú
  Future<void> deleteForever(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    notifyListeners();
    await _localStorage.saveNotes(_notes);

    if (_currentUserId != null) {
      try {
        await _firestoreSync.deleteNoteFromCloud(_currentUserId!, noteId);
      } catch (_) {}
    }
  }

  /// Dọn sạch toàn bộ thùng rác
  Future<void> emptyTrash() async {
    final trashIds = _notes.where((n) => n.isDeleted).map((n) => n.id).toList();
    _notes.removeWhere((n) => n.isDeleted);
    notifyListeners();
    await _localStorage.saveNotes(_notes);

    if (_currentUserId != null) {
      for (final id in trashIds) {
        try {
          await _firestoreSync.deleteNoteFromCloud(_currentUserId!, id);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}
