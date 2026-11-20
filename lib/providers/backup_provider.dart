import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import '../models/drive_backup_metadata.dart';
import '../services/google_drive_service.dart';
import 'notes_provider.dart';

/// Trạng thái của lần tự động sao lưu gần nhất.
enum AutoBackupStatus { idle, running, success, failed }

/// Quản lý trạng thái và thao tác Sao lưu / Khôi phục Google Drive
class BackupProvider extends ChangeNotifier {
  static const String _autoEnabledKey = 'tn_note_auto_backup_enabled';
  static const String _autoFingerprintKey = 'tn_note_auto_backup_fingerprint';
  static const String _autoLastAtKey = 'tn_note_auto_backup_last_at';
  static const String _autoLastStatusKey = 'tn_note_auto_backup_last_status';
  static const String _autoLastErrorKey = 'tn_note_auto_backup_last_error';
  static const String _autoLastNoteCountKey =
      'tn_note_auto_backup_last_note_count';

  final GoogleDriveService _driveService = GoogleDriveService();

  List<DriveBackupMetadata> _backups = [];
  bool _isLoadingList = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _errorMessage;
  String? _statusMessage;
  DateTime? _lastBackupDate;

  bool _autoBackupEnabled = false;
  bool _isAutoBackupRunning = false;
  bool _autoBackupSettingsLoaded = false;
  AutoBackupStatus _autoBackupStatus = AutoBackupStatus.idle;
  String? _autoBackupFingerprint;
  DateTime? _lastAutoBackupAt;
  String? _lastAutoBackupError;
  int _lastAutoBackupNoteCount = 0;

  List<DriveBackupMetadata> get backups => _backups;
  bool get isLoadingList => _isLoadingList;
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  bool get autoBackupEnabled => _autoBackupEnabled;
  bool get isAutoBackupRunning => _isAutoBackupRunning;
  bool get autoBackupSettingsLoaded => _autoBackupSettingsLoaded;
  AutoBackupStatus get autoBackupStatus => _autoBackupStatus;
  DateTime? get lastAutoBackupDate => _lastAutoBackupAt;
  String? get lastAutoBackupError => _lastAutoBackupError;
  int get lastAutoBackupNoteCount => _lastAutoBackupNoteCount;

  DateTime? get lastBackupDate {
    DateTime? latest = _lastBackupDate;
    if (_lastAutoBackupAt != null &&
        (latest == null || _lastAutoBackupAt!.isAfter(latest))) {
      latest = _lastAutoBackupAt;
    }
    if (_backups.isNotEmpty) {
      final newestListed = _backups.first.createdTime;
      if (latest == null || newestListed.isAfter(latest)) {
        latest = newestListed;
      }
    }
    return latest;
  }

  BackupProvider() {
    _loadAutoBackupSettings();
  }

  Future<void> _loadAutoBackupSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoBackupEnabled = prefs.getBool(_autoEnabledKey) ?? false;

      final storedFingerprint = prefs.getString(_autoFingerprintKey);
      _autoBackupFingerprint =
          (storedFingerprint != null && storedFingerprint.isNotEmpty)
              ? storedFingerprint
              : null;

      final lastAt = prefs.getInt(_autoLastAtKey);
      _lastAutoBackupAt = (lastAt != null && lastAt > 0)
          ? DateTime.fromMillisecondsSinceEpoch(lastAt)
          : null;

      _lastAutoBackupError = prefs.getString(_autoLastErrorKey);
      _lastAutoBackupNoteCount = prefs.getInt(_autoLastNoteCountKey) ?? 0;

      final storedStatus = prefs.getString(_autoLastStatusKey);
      _autoBackupStatus = switch (storedStatus) {
        'success' => AutoBackupStatus.success,
        'failed' => AutoBackupStatus.failed,
        _ => AutoBackupStatus.idle,
      };
    } catch (_) {
      // SharedPreferences không khả dụng: giữ cấu hình mặc định.
    } finally {
      _autoBackupSettingsLoaded = true;
      notifyListeners();
    }
  }

  /// Bật/tắt tính năng tự động sao lưu.
  Future<void> setAutoBackupEnabled(bool enabled) async {
    if (_autoBackupEnabled == enabled) return;

    _autoBackupEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoEnabledKey, enabled);
    } catch (_) {
      // Không chặn thao tác bật/tắt nếu lưu cấu hình thất bại.
    }
  }

  /// Kiểm tra dữ liệu hiện tại có thay đổi so với lần auto backup gần nhất không.
  bool hasPendingAutoBackup({
    required GoogleSignInAccount? account,
    required List<NoteModel> notes,
  }) {
    if (!_autoBackupEnabled || account == null || notes.isEmpty) return false;
    return _buildFingerprint(account, notes) != _autoBackupFingerprint;
  }

  /// Thực hiện auto backup nếu dữ liệu đã thay đổi kể từ lần trước.
  ///
  /// Trả về `true` khi có bản sao lưu mới được tạo/cập nhật thành công.
  Future<bool> runAutoBackup({
    required GoogleSignInAccount account,
    required List<NoteModel> notes,
  }) async {
    if (_isAutoBackupRunning) return false;
    if (!_autoBackupEnabled) return false;
    if (notes.isEmpty) return false;

    // Chụp lại dữ liệu tại thời điểm bắt đầu để fingerprint và nội dung
    // tải lên luôn khớp nhau, kể cả khi người dùng sửa ghi chú trong lúc chờ mạng.
    final snapshot = List<NoteModel>.from(notes);
    final fingerprint = _buildFingerprint(account, snapshot);
    if (fingerprint == _autoBackupFingerprint) return false;

    _isAutoBackupRunning = true;
    _autoBackupStatus = AutoBackupStatus.running;
    _lastAutoBackupError = null;
    notifyListeners();

    try {
      final autoBackup = await _driveService.saveAutoBackup(
        account: account,
        notes: snapshot,
        description: 'Tự động sao lưu ${snapshot.length} ghi chú',
      );

      _autoBackupFingerprint = fingerprint;
      _lastAutoBackupAt = autoBackup.createdTime;
      _lastAutoBackupNoteCount = snapshot.length;
      _autoBackupStatus = AutoBackupStatus.success;
      _lastAutoBackupError = null;
      _lastBackupDate = autoBackup.createdTime;

      _backups.removeWhere((item) => item.id == autoBackup.id);
      _backups.insert(0, autoBackup);

      await _persistAutoBackupState();
      return true;
    } catch (e) {
      _autoBackupStatus = AutoBackupStatus.failed;
      _lastAutoBackupError = _friendlyError(e);
      await _persistAutoBackupState();
      return false;
    } finally {
      _isAutoBackupRunning = false;
      notifyListeners();
    }
  }

  Future<void> _persistAutoBackupState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_autoBackupFingerprint != null) {
        await prefs.setString(_autoFingerprintKey, _autoBackupFingerprint!);
      } else {
        await prefs.remove(_autoFingerprintKey);
      }

      if (_lastAutoBackupAt != null) {
        await prefs.setInt(
          _autoLastAtKey,
          _lastAutoBackupAt!.millisecondsSinceEpoch,
        );
      } else {
        await prefs.remove(_autoLastAtKey);
      }

      await prefs.setString(_autoLastStatusKey, _autoBackupStatus.name);
      await prefs.setInt(
        _autoLastNoteCountKey,
        _lastAutoBackupNoteCount,
      );

      if (_lastAutoBackupError != null) {
        await prefs.setString(_autoLastErrorKey, _lastAutoBackupError!);
      } else {
        await prefs.remove(_autoLastErrorKey);
      }
    } catch (_) {
      // Không để lỗi lưu trạng thái làm hỏng luồng sao lưu.
    }
  }

  String _buildFingerprint(
    GoogleSignInAccount account,
    List<NoteModel> notes,
  ) {
    final entries = notes
        .map((note) => '${note.id}:${note.updatedAt.millisecondsSinceEpoch}')
        .toList()
      ..sort();
    final data = entries.join('|');

    // FNV-1a 32-bit: ổn định giữa các lần chạy ứng dụng (không dùng hashCode).
    var hash = 0x811C9DC5;
    for (final codeUnit in data.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }

    final accountKey =
        account.email.isNotEmpty ? account.email.toLowerCase() : account.id;
    return '$accountKey|${notes.length}|${hash.toRadixString(16)}';
  }

  String _friendlyError(Object error) {
    final raw = error.toString();
    if (raw.contains('401') || raw.contains('403')) {
      return 'Phiên đăng nhập Google đã hết hạn hoặc chưa cấp quyền Drive. Vui lòng kết nối lại tài khoản Google.';
    }
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Connection')) {
      return 'Không có kết nối mạng. T-Note sẽ tự thử lại khi có mạng.';
    }
    return raw;
  }

  /// Lấy danh sách các bản sao lưu từ Google Drive
  Future<void> fetchBackups(GoogleSignInAccount? account) async {
    if (account == null) {
      _backups = [];
      _lastBackupDate = null;
      notifyListeners();
      return;
    }

    _isLoadingList = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _backups = await _driveService.listBackups(account);
      _lastBackupDate = _backups.isNotEmpty ? _backups.first.createdTime : null;
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
      _statusMessage =
          'Đã sao lưu ${notes.length} ghi chú lên Google Drive thành công!';
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

      await notesProvider.restoreNotesFromBackup(
        restoredNotes,
        overwrite: overwrite,
      );
      _statusMessage =
          'Khôi phục thành công ${restoredNotes.length} ghi chú từ Google Drive!';
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
