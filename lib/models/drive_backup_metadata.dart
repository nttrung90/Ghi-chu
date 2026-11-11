/// Thông tin tệp sao lưu lưu trữ trên Google Drive cá nhân
class DriveBackupMetadata {
  final String id;
  final String name;
  final DateTime createdTime;
  final int sizeInBytes;
  final int noteCount;
  final String description;

  DriveBackupMetadata({
    required this.id,
    required this.name,
    required this.createdTime,
    this.sizeInBytes = 0,
    this.noteCount = 0,
    this.description = '',
  });

  /// Định dạng dung lượng tệp dễ đọc (B, KB, MB)
  String get formattedSize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
