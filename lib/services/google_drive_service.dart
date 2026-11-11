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

  /// Khởi tạo Drive API Client với tài khoản người dùng
  drive.DriveApi _getDriveApi(GoogleSignInAccount account) {
    final client = GoogleAuthClient(() => account.authHeaders);
    return drive.DriveApi(client);
  }

  /// Tìm hoặc tạo thư mục 'T-Note Backups' trên Google Drive cá nhân
  Future<String> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    try {
      final search = await driveApi.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = '$backupFolderName' and trashed = false",
        $fields: 'files(id, name)',
        spaces: 'drive',
      );

      if (search.files != null && search.files!.isNotEmpty) {
        return search.files!.first.id!;
      }

      final folderMeta = drive.File()
        ..name = backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await driveApi.files.create(
        folderMeta,
        $fields: 'id',
      );
      return createdFolder.id!;
    } catch (e) {
      // Nếu gặp lỗi tìm/tạo thư mục, fallback lưu ở thư mục gốc (root)
      return 'root';
    }
  }

  /// Tạo bản sao lưu toàn bộ ghi chú lên Google Drive
  Future<DriveBackupMetadata> createBackup({
    required GoogleSignInAccount account,
    required List<NoteModel> notes,
    String? description,
  }) async {
    final driveApi = _getDriveApi(account);
    final folderId = await _getOrCreateBackupFolder(driveApi);

    final now = DateTime.now();
    final timestampStr = "${now.year.toString().padLeft(4, '0')}"
        "${now.month.toString().padLeft(2, '0')}"
        "${now.day.toString().padLeft(2, '0')}_"
        "${now.hour.toString().padLeft(2, '0')}"
        "${now.minute.toString().padLeft(2, '0')}"
        "${now.second.toString().padLeft(2, '0')}";

    final fileName = 'T-Note_Backup_$timestampStr.json';

    final backupPayload = {
      'appName': 'T-Note',
      'appVersion': '0.1.0',
      'version': 1,
      'createdAt': now.toIso8601String(),
      'description': description ?? 'Bản sao lưu ghi chú cá nhân',
      'totalNotes': notes.length,
      'notes': notes.map((n) => n.toMap()).toList(),
    };

    final jsonString = jsonEncode(backupPayload);
    final bytes = utf8.encode(jsonString);
    final stream = Stream<List<int>>.value(bytes);
    final media = drive.Media(stream, bytes.length);

    final driveFile = drive.File()
      ..name = fileName
      ..parents = folderId != 'root' ? [folderId] : null
      ..description = description ?? 'Bản sao lưu T-Note gồm ${notes.length} ghi chú'
      ..properties = {
        'totalNotes': notes.length.toString(),
        'app': 'T-Note',
      }
      ..mimeType = 'application/json';

    final uploadedFile = await driveApi.files.create(
      driveFile,
      uploadMedia: media,
      $fields: 'id, name, createdTime, size, description',
    );

    return DriveBackupMetadata(
      id: uploadedFile.id ?? '',
      name: uploadedFile.name ?? fileName,
      createdTime: uploadedFile.createdTime?.toLocal() ?? now,
      sizeInBytes: int.tryParse(uploadedFile.size ?? '') ?? bytes.length,
      noteCount: notes.length,
      description: uploadedFile.description ?? '',
    );
  }

  /// Lấy danh sách tất cả các bản sao lưu hiện có trên Google Drive
  Future<List<DriveBackupMetadata>> listBackups(GoogleSignInAccount account) async {
    final driveApi = _getDriveApi(account);

    final result = await driveApi.files.list(
      q: "name contains 'T-Note_Backup_' and mimeType = 'application/json' and trashed = false",
      $fields: 'files(id, name, createdTime, size, description, properties)',
      orderBy: 'createdTime desc',
      spaces: 'drive',
    );

    final List<DriveBackupMetadata> backups = [];
    if (result.files != null) {
      for (final file in result.files!) {
        int noteCount = 0;
        if (file.properties != null && file.properties!.containsKey('totalNotes')) {
          noteCount = int.tryParse(file.properties!['totalNotes'] ?? '0') ?? 0;
        }

        backups.add(DriveBackupMetadata(
          id: file.id ?? '',
          name: file.name ?? 'Bản sao lưu',
          createdTime: file.createdTime?.toLocal() ?? DateTime.now(),
          sizeInBytes: int.tryParse(file.size ?? '0') ?? 0,
          noteCount: noteCount,
          description: file.description ?? '',
        ));
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
  }
}
