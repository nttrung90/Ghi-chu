import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

/// Dịch vụ lưu trữ cục bộ (Local Storage)
/// Đảm bảo tính năng Offline-First: Ứng dụng khởi động ngay lập tức không cần mạng
class LocalStorageService {
  static const String _notesKey = 'note_ntt_local_notes';
  static const String _pendingSyncKey = 'note_ntt_pending_sync';

  /// Lưu danh sách toàn bộ ghi chú vào bộ nhớ máy
  Future<void> saveNotes(List<NoteModel> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJsonList = notes.map((n) => n.toJson()).toList();
    await prefs.setStringList(_notesKey, notesJsonList);
  }

  /// Đọc danh sách ghi chú từ bộ nhớ máy
  Future<List<NoteModel>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? notesJsonList = prefs.getStringList(_notesKey);

    if (notesJsonList == null || notesJsonList.isEmpty) {
      return [];
    }

    try {
      return notesJsonList.map((jsonStr) => NoteModel.fromJson(jsonStr)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Đánh dấu ID ghi chú cần đẩy lên Firebase khi có mạng lại
  Future<void> markForSync(String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_pendingSyncKey) ?? [];
    if (!pending.contains(noteId)) {
      pending.add(noteId);
      await prefs.setStringList(_pendingSyncKey, pending);
    }
  }

  /// Lấy danh sách ID các ghi chú chưa đồng bộ
  Future<List<String>> getPendingSyncIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pendingSyncKey) ?? [];
  }

  /// Xóa khỏi danh sách chờ đồng bộ sau khi đã đẩy lên Firebase thành công
  Future<void> removePendingSyncId(String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_pendingSyncKey) ?? [];
    pending.remove(noteId);
    await prefs.setStringList(_pendingSyncKey, pending);
  }
}
