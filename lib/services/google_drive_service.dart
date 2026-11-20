import 'dart:async';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../models/note_model.dart';
import '../models/drive_backup_metadata.dart';

/// HTTP Client tự động đính kèm Token xác thực của Google Sign-In
class GoogleAuthClient extends http.BaseClient {
  final Future<Map<String, String>> Function() _getHeaders;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._getHeaders);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await _getHeaders();
    request.headers.addAll(headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

/// Dịch vụ quản lý Sao lưu và Khôi phục ghi chú qua Google Drive cá nhân
class GoogleDriveService {
  static const String backupFolderName = 'T-Note Backups';

  /// Tên tệp cố định dùng cho tính năng tự động sao lưu.
  /// Mỗi tài khoản Google chỉ có duy nhất một tệp này và được ghi đè mỗi lần sao lưu.
  static const String autoBackupFileName = 'T-Note_Backup_Auto.json';

  static const String _backupMimeType = 'application/json';
  static const String _fileFields =
      'id, name, createdTime, modifiedTime, size, description, properties';

  /// Cache ID thư mục/tệp auto theo tài khoản để giảm số lần gọi Drive API.
  final Map<String, String> _folderIds = {};
  final Map<String, String> _autoFileIds = {};

  /// Khởi tạo Drive API Client với tài khoản người dùng
  drive.DriveApi _getDriveApi(GoogleSignInAccount account) {
    final client = GoogleAuthClient(() => account.authHeaders);
    return drive.DriveApi(client);
  }

  String _accountKey(GoogleSignInAccount account) =>
      account.email.isNotEmpty ? account.email.toLowerCase() : account.id;

  /// Tìm hoặc tạo thư mục 'T-Note Backups' trên Google Drive cá nhân
  Future<String> _getOrCreateBackupFolder(
    drive.DriveApi driveApi,
    GoogleSignInAccount account,
  ) async {
    final accountKey = _accountKey(account);
    final cachedFolderId = _folderIds[accountKey];
    if (cachedFolderId != null) return cachedFolderId;

    try {
      final search = await driveApi.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = '$backupFolderName' and trashed = false",
        $fields: 'files(id, name)',
        spaces: 'drive',
      );

      if (search.files != null && search.files!.isNotEmpty) {
        final folderId = search.files!.first.id!;
        _folderIds[accountKey] = folderId;
        return folderId;
      }

      final folderMeta = drive.File()
        ..name = backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await driveApi.files.create(
        folderMeta,
        $fields: 'id',
      );
      final folderId = createdFolder.id!;
      _folderIds[accountKey] = folderId;
      return folderId;
    } catch (e) {
      // Nếu gặp lỗi tìm/tạo thư mục, fallback lưu ở thư mục gốc (root).
      // Không cache 'root' để lần sau còn thử tìm lại thư mục riêng.
      return 'root';
    }
  }

  Map<String, dynamic> _buildBackupPayload({
    required List<NoteModel> notes,
    required DateTime createdAt,
    required String description,
    bool isAutoBackup = false,
  }) {
    return {
      'appName': 'T-Note',
      'appVersion': '0.1.2',
      'version': 1,
      'createdAt': createdAt.toIso8601String(),
      if (isAutoBackup) 'autoBackup': true,
      'description': description,
      'totalNotes': notes.length,
      'notes': notes.map((n) => n.toMap()).toList(),
    };
  }

  drive.Media _mediaFromBytes(List<int> bytes) =>
      drive.Media(Stream<List<int>>.value(bytes), bytes.length);

  DriveBackupMetadata _metadataFromFile(
    drive.File file, {
    required String fallbackName,
    required int noteCount,
    required DateTime fallbackTime,
    required int fallbackSize,
  }) {
    return DriveBackupMetadata(
      id: file.id ?? '',
      name: file.name ?? fallbackName,
      // Với tệp auto, modifiedTime chính là thời điểm sao lưu gần nhất.
      createdTime:
          (file.modifiedTime ?? file.createdTime)?.toLocal() ?? fallbackTime,
      sizeInBytes: int.tryParse(file.size ?? '') ?? fallbackSize,
      noteCount: noteCount,
      description: file.description ?? '',
    );
  }

  drive.File _autoBackupFileRequest({
    required String description,
    required int noteCount,
  }) {
    return drive.File()
      ..name = autoBackupFileName
      ..description = description
      ..properties = {
        'totalNotes': noteCount.toString(),
        'app': 'T-Note',
        'autoBackup': 'true',
      }
      ..mimeType = _backupMimeType;
  }

  Future<drive.File?> _findAutoBackupFile(drive.DriveApi driveApi) async {
    final result = await driveApi.files.list(
      q: "name = '$autoBackupFileName' and mimeType = '$_backupMimeType' and trashed = false",
      $fields: 'files($_fileFields)',
      orderBy: 'modifiedTime desc',
      spaces: 'drive',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first;
    }
    return null;
  }

  /// Tạo bản sao lưu toàn bộ ghi chú lên Google Drive
  Future<DriveBackupMetadata> createBackup({
    required GoogleSignInAccount account,
    required List<NoteModel> notes,
    String? description,
  }) async {
    final driveApi = _getDriveApi(account);
    final accountKey = _accountKey(account);
    final folderId = await _getOrCreateBackupFolder(driveApi, account);

    final now = DateTime.now();
    final timestampStr = "${now.year.toString().padLeft(4, '0')}"
        "${now.month.toString().padLeft(2, '0')}"
        "${now.day.toString().padLeft(2, '0')}_"
        "${now.hour.toString().padLeft(2, '0')}"
        "${now.minute.toString().padLeft(2, '0')}"
        "${now.second.toString().padLeft(2, '0')}";

    final fileName = 'T-Note_Backup_$timestampStr.json';
    final backupDescription =
        description ?? 'Bản sao lưu T-Note gồm ${notes.length} ghi chú';

    final bytes = utf8.encode(
      jsonEncode(
        _buildBackupPayload(
          notes: notes,
          createdAt: now,
          description: description ?? 'Bản sao lưu ghi chú cá nhân',
        ),
      ),
    );

    final driveFile = drive.File()
      ..name = fileName
      ..parents = folderId != 'root' ? [folderId] : null
      ..description = backupDescription
      ..properties = {
        'totalNotes': notes.length.toString(),
        'app': 'T-Note',
      }
      ..mimeType = _backupMimeType;

    try {
      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: _mediaFromBytes(bytes),
        $fields: _fileFields,
      );

      return _metadataFromFile(
        uploadedFile,
        fallbackName: fileName,
        noteCount: notes.length,
        fallbackTime: now,
        fallbackSize: bytes.length,
      );
    } catch (e) {
      // Thư mục có thể đã bị xóa/không còn quyền truy cập; lần sau tìm lại.
      _folderIds.remove(accountKey);
      rethrow;
    }
  }

  /// Cập nhật (hoặc tạo mới nếu chưa có) tệp sao lưu tự động cố định.
  ///
  /// Nhờ dùng `files.update`, lịch sử Google Drive không bị sinh thêm tệp mới
  /// sau mỗi lần người dùng chỉnh sửa ghi chú.
  Future<DriveBackupMetadata> saveAutoBackup({
    required GoogleSignInAccount account,
    required List<NoteModel> notes,
    String? description,
  }) async {
    final driveApi = _getDriveApi(account);
    final accountKey = _accountKey(account);
    final folderId = await _getOrCreateBackupFolder(driveApi, account);

    final now = DateTime.now();
    final backupDescription =
        description ?? 'Tự động sao lưu T-Note gồm ${notes.length} ghi chú';

    final bytes = utf8.encode(
      jsonEncode(
        _buildBackupPayload(
          notes: notes,
          createdAt: now,
          description: backupDescription,
          isAutoBackup: true,
        ),
      ),
    );

    try {
      drive.File? updatedFile;

      // 1. Ưu tiên cập nhật bằng ID đã cache để tiết kiệm một lượt tìm kiếm.
      final cachedFileId = _autoFileIds[accountKey];
      if (cachedFileId != null) {
        try {
          updatedFile = await driveApi.files.update(
            _autoBackupFileRequest(
              description: backupDescription,
              noteCount: notes.length,
            ),
            cachedFileId,
            uploadMedia: _mediaFromBytes(bytes),
            $fields: _fileFields,
          );
        } catch (_) {
          // Tệp có thể đã bị xóa hoặc cache không còn đúng.
          _autoFileIds.remove(accountKey);
        }
      }

      // 2. Nếu chưa có cache (hoặc cache lỗi), tìm tệp auto hiện có.
      if (updatedFile == null) {
        final existingFile = await _findAutoBackupFile(driveApi);
        if (existingFile?.id != null) {
          updatedFile = await driveApi.files.update(
            _autoBackupFileRequest(
              description: backupDescription,
              noteCount: notes.length,
            ),
            existingFile!.id!,
            uploadMedia: _mediaFromBytes(bytes),
            $fields: _fileFields,
          );
          _autoFileIds[accountKey] = existingFile.id!;
        }
      }

      // 3. Chưa từng có tệp auto: tạo mới trong thư mục sao lưu.
      if (updatedFile == null) {
        final createdFile = await driveApi.files.create(
          _autoBackupFileRequest(
            description: backupDescription,
            noteCount: notes.length,
          )..parents = folderId != 'root' ? [folderId] : null,
          uploadMedia: _mediaFromBytes(bytes),
          $fields: _fileFields,
        );
        if (createdFile.id != null) {
          _autoFileIds[accountKey] = createdFile.id!;
        }
        return _metadataFromFile(
          createdFile,
          fallbackName: autoBackupFileName,
          noteCount: notes.length,
          fallbackTime: now,
          fallbackSize: bytes.length,
        );
      }

      return _metadataFromFile(
        updatedFile,
        fallbackName: autoBackupFileName,
        noteCount: notes.length,
        fallbackTime: now,
        fallbackSize: bytes.length,
      );
    } catch (e) {
      _folderIds.remove(accountKey);
      rethrow;
    }
  }

  /// Lấy danh sách tất cả các bản sao lưu hiện có trên Google Drive
  Future<List<DriveBackupMetadata>> listBackups(
    GoogleSignInAccount account,
  ) async {
    final driveApi = _getDriveApi(account);

    final result = await driveApi.files.list(
      q: "name contains 'T-Note_Backup_' and mimeType = '$_backupMimeType' and trashed = false",
      $fields: 'files($_fileFields)',
      // Tệp auto được cập nhật liên tục, nên modifiedTime phản ánh đúng
      // thời điểm sao lưu gần nhất và giúp tệp luôn đứng đầu lịch sử.
      orderBy: 'modifiedTime desc',
      spaces: 'drive',
    );

    final List<DriveBackupMetadata> backups = [];
    if (result.files != null) {
      for (final file in result.files!) {
        int noteCount = 0;
        if (file.properties != null &&
            file.properties!.containsKey('totalNotes')) {
          noteCount = int.tryParse(file.properties!['totalNotes'] ?? '0') ?? 0;
        }

        backups.add(
          DriveBackupMetadata(
            id: file.id ?? '',
            name: file.name ?? 'Bản sao lưu',
            createdTime: (file.modifiedTime ?? file.createdTime)?.toLocal() ??
                DateTime.now(),
            sizeInBytes: int.tryParse(file.size ?? '0') ?? 0,
            noteCount: noteCount,
            description: file.description ?? '',
          ),
        );
      }
    }
    return backups;
  }

  /// Tải về và phân giải danh sách ghi chú từ một bản sao lưu trên Google Drive
  Future<List<NoteModel>> downloadBackup({
    required GoogleSignInAccount account,
    required String fileId,
  }) async {
    final driveApi = _getDriveApi(account);

    final dynamic result = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (result is! drive.Media) {
      throw Exception('Không thể tải tệp sao lưu từ Google Drive.');
    }

    final List<int> bytes = [];
    await for (final chunk in result.stream) {
      bytes.addAll(chunk);
    }

    final jsonString = utf8.decode(bytes);
    final Map<String, dynamic> data = jsonDecode(jsonString);

    if (data['notes'] != null && data['notes'] is List) {
      final List notesList = data['notes'];
      return notesList
          .map((item) => NoteModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return [];
  }

  /// Xóa vĩnh viễn một bản sao lưu khỏi Google Drive
  Future<void> deleteBackup({
    required GoogleSignInAccount account,
    required String fileId,
  }) async {
    final driveApi = _getDriveApi(account);
    await driveApi.files.delete(fileId);

    // Nếu xóa đúng tệp auto đang được cache, bỏ cache để lần sau tạo lại sạch sẽ.
    _autoFileIds.removeWhere((_, cachedId) => cachedId == fileId);
  }
}
