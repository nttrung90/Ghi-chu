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
  bool _showUncategorized = false;
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _currentUserId;
  StreamSubscription<List<NoteModel>>? _firestoreSubscription;

  List<NoteModel> get allNotes => _notes;
  SyncStatus get syncStatus => _syncStatus;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;
  bool get showUncategorized => _showUncategorized;

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
    if (tag != null) {
      _showUncategorized = false;
    }
    notifyListeners();
  }

  /// Bỏ mọi bộ lọc danh mục và quay về danh sách tất cả ghi chú.
  void showAllNotes() {
    _selectedTag = null;
    _showUncategorized = false;
    notifyListeners();
  }

  /// Chỉ hiển thị các ghi chú chưa được gắn nhãn.
  void setUncategorizedOnly(bool value) {
    _showUncategorized = value;
    if (value) {
      _selectedTag = null;
    }
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

  /// Có ghi chú nào chưa được gắn nhãn hay không.
  bool get hasUncategorizedNotes => _notes.any(
        (note) => !note.isDeleted && !note.isArchived && note.tags.isEmpty,
      );

  /// Các ghi chú đang hoạt động, chưa bị xóa và chưa lưu trữ.
  List<NoteModel> get activeNotes =>
      _notes.where((note) => !note.isDeleted && !note.isArchived).toList();

  /// Các ghi chú đang hoạt động và khớp với từ khóa tìm kiếm (không lọc nhãn).
  List<NoteModel> get searchFilteredActiveNotes =>
      activeNotes.where(_matchesSearch).toList();

  bool _matchesSearch(NoteModel note) {
    if (_searchQuery.isEmpty) return true;

    final matchesTitle = note.title.toLowerCase().contains(_searchQuery);
    final matchesContent = note.content.toLowerCase().contains(_searchQuery);
    final matchesTag =
        note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
    final matchesChecklist = note.checklist
        .any((item) => item.text.toLowerCase().contains(_searchQuery));

    return matchesTitle || matchesContent || matchesTag || matchesChecklist;
  }

  /// Số lượng ghi chú đang hoạt động.
  int get activeNotesCount => activeNotes.length;

  /// Tổng số đầu việc trong tất cả ghi chú đang hoạt động.
  int get totalChecklistItems => activeNotes.fold(
        0,
        (total, note) => total + note.checklist.length,
      );

  /// Số đầu việc chưa hoàn thành trong tất cả ghi chú đang hoạt động.
  int get pendingChecklistItems => activeNotes.fold(
        0,
        (total, note) =>
            total + note.checklist.where((item) => !item.isDone).length,
      );

  /// Các ghi chú đang hoạt động (không bị xóa, không bị lưu trữ) sau khi lọc
  List<NoteModel> get filteredActiveNotes {
    return _notes.where((note) {
      if (note.isDeleted || note.isArchived) return false;

      // Lọc theo nhãn
      if (_selectedTag != null && !note.tags.contains(_selectedTag)) {
        return false;
      }

      // Lọc ghi chú chưa phân loại
      if (_showUncategorized && note.tags.isNotEmpty) {
        return false;
      }

      // Lọc theo từ khóa tìm kiếm
      if (!_matchesSearch(note)) {
        return false;
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

  /// Đánh dấu hoàn thành / chưa hoàn thành một đầu việc trong ghi chú.
  Future<void> toggleChecklistItem(String noteId, String itemId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index < 0) return;

    final note = _notes[index];
    final updatedChecklist = note.checklist
        .map(
          (item) =>
              item.id == itemId ? item.copyWith(isDone: !item.isDone) : item,
        )
        .toList();

    await saveNote(note.copyWith(checklist: updatedChecklist));
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

  /// Khôi phục ghi chú từ bản sao lưu (Google Drive)
  /// - Nếu [overwrite] == true: Thay thế toàn bộ danh sách ghi chú
  /// - Nếu [overwrite] == false: Gộp thông minh (giữ lại bản ghi có updatedAt mới hơn)
  Future<void> restoreNotesFromBackup(List<NoteModel> backupNotes,
      {bool overwrite = false}) async {
    if (overwrite) {
      _notes = List.from(backupNotes);
    } else {
      final Map<String, NoteModel> map = {for (var n in _notes) n.id: n};
      for (final bNote in backupNotes) {
        if (!map.containsKey(bNote.id)) {
          map[bNote.id] = bNote;
        } else {
          final current = map[bNote.id]!;
          if (bNote.updatedAt.isAfter(current.updatedAt)) {
            map[bNote.id] = bNote;
          }
        }
      }
      _notes = map.values.toList();
    }

    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();

    // Lưu vào bộ nhớ máy Offline-first
    await _localStorage.saveNotes(_notes);

    // Đồng bộ lên Firebase Firestore nếu đang đăng nhập
    if (_currentUserId != null) {
      try {
        await _firestoreSync.syncBatch(_currentUserId!, _notes);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}
