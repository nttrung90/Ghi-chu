import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

/// Dịch vụ đồng bộ dữ liệu thời gian thực qua Cloud Firestore
class FirestoreSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy Collection Reference cho người dùng cụ thể
  CollectionReference<Map<String, dynamic>> _userNotesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  /// Lắng nghe luồng dữ liệu thời gian thực từ Firestore (Realtime Stream)
  Stream<List<NoteModel>> streamNotes(String userId) {
    return _userNotesCollection(userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Đảm bảo ID đồng nhất
        return NoteModel.fromMap(data);
      }).toList();
    });
  }

  /// Đẩy một ghi chú lên Cloud Firestore (Tạo mới hoặc Cập nhật)
  Future<void> saveNoteToCloud(String userId, NoteModel note) async {
    try {
      await _userNotesCollection(userId).doc(note.id).set(
            note.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      // Lỗi mạng hoặc offline, Firestore SDK tự động cache vào local persistence
      rethrow;
    }
  }

  /// Xóa vĩnh viễn ghi chú khỏi đám mây
  Future<void> deleteNoteFromCloud(String userId, String noteId) async {
    try {
      await _userNotesCollection(userId).doc(noteId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Đồng bộ hàng loạt danh sách ghi chú (khi mới đăng nhập hoặc sau khi offline)
  Future<void> syncBatch(String userId, List<NoteModel> notes) async {
    final batch = _firestore.batch();
    for (final note in notes) {
      final docRef = _userNotesCollection(userId).doc(note.id);
      batch.set(docRef, note.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
