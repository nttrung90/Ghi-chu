import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/note_model.dart';
import '../models/drive_backup_metadata.dart';
import '../services/google_drive_service.dart';
import 'notes_provider.dart';

/// Quản lý trạng thái và thao tác Sao lưu / Khôi phục Google Drive
class BackupProvider extends ChangeNotifier {
  final GoogleDriveService _driveService = GoogleDriveService();

  List<DriveBackupMetadata> _backups = [];
  bool _isLoadingList = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _errorMessage;
  String? _statusMessage;
  DateTime? _lastBackupDate;

  List<DriveBackupMetadata> get backups => _backups;
  bool get isLoadingList => _isLoadingList;
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  DateTime? get lastBackupDate => _lastBackupDate ?? (_backups.isNotEmpty ? _backups.first.createdTime : null);

  /// Lấy danh sách các bản sao lưu từ Google Drive
  Future<void> fetchBackups(GoogleSignInAccount? account) async {
    if (account == null) {
      _backups = [];
      notifyListeners();
      return;
    }

    _isLoadingList = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _backups = await _driveService.listBackups(account);
      if (_backups.isNotEmpty) {
        _lastBackupDate = _backups.first.createdTime;
      }
    } catch (e) {
      _errorMessage = 'Lỗi tải danh sách sao lưu: $e';
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  /// Tạo bản sao lưu mới lên Google Drive
  Future<bool> createBackup({
    required GoogleSignInAccount account,
    required List<NoteModel> notes,
    String? description,
  }) async {
    _isBackingUp = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      final newBackup = await _driveService.createBackup(
        account: account,
        notes: notes,
        description: description,
      );
      _backups.insert(0, newBackup);
      _lastBackupDate = newBackup.createdTime;
      _statusMessage = 'Đã sao lưu ${notes.length} ghi chú lên Google Drive thành công!';
      return true;
    } catch (e) {
      _errorMessage = 'Sao lưu thất bại: $e';
      return false;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  /// Khôi phục ghi chú từ một bản sao lưu trên Google Drive
  Future<bool> restoreBackup({
    required GoogleSignInAccount account,
    required String fileId,
    required NotesProvider notesProvider,
    bool overwrite = false,
  }) async {
    _isRestoring = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      final restoredNotes = await _driveService.downloadBackup(
        account: account,
        fileId: fileId,
      );

      if (restoredNotes.isEmpty) {
        _errorMessage = 'Bản sao lưu trống hoặc không có ghi chú nào.';
        return false;
      }

      await notesProvider.restoreNotesFromBackup(restoredNotes, overwrite: overwrite);
      _statusMessage = 'Khôi phục thành công ${restoredNotes.length} ghi chú từ Google Drive!';
      return true;
    } catch (e) {
      _errorMessage = 'Khôi phục thất bại: $e';
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Xóa một bản sao lưu trên Google Drive
  Future<bool> deleteBackup({
    required GoogleSignInAccount account,
    required String fileId,
  }) async {
    try {
      await _driveService.deleteBackup(
        account: account,
        fileId: fileId,
      );
      _backups.removeWhere((b) => b.id == fileId);
      _statusMessage = 'Đã xóa bản sao lưu khỏi Google Drive.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Xóa bản sao lưu thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }
}
