import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/drive_backup_metadata.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backup_provider.dart';
import '../../providers/notes_provider.dart';

class GoogleDriveBackupScreen extends StatefulWidget {
  const GoogleDriveBackupScreen({super.key});

  @override
  State<GoogleDriveBackupScreen> createState() => _GoogleDriveBackupScreenState();
}

class _GoogleDriveBackupScreenState extends State<GoogleDriveBackupScreen> {
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBackups();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadBackups() {
    final auth = context.read<AuthProvider>();
    final backup = context.read<BackupProvider>();
    if (auth.googleUser != null) {
      backup.fetchBackups(auth.googleUser);
    }
  }

  Future<void> _handleConnectGoogle() async {
    final auth = context.read<AuthProvider>();
    final account = await auth.connectGoogleAccount();
    if (account != null && mounted) {
      context.read<BackupProvider>().fetchBackups(account);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã liên kết tài khoản Google: ${account.email}')),
      );
    }
  }

  Future<void> _handleBackupNow() async {
    final auth = context.read<AuthProvider>();
    final notes = context.read<NotesProvider>();
    final backup = context.read<BackupProvider>();

    if (auth.googleUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập Google trước khi sao lưu')),
      );
      return;
    }

    final success = await backup.createBackup(
      account: auth.googleUser!,
      notes: notes.allNotes,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    if (mounted) {
      if (success) {
        _descriptionController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(backup.statusMessage ?? 'Sao lưu thành công!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(backup.errorMessage ?? 'Sao lưu thất bại'),
          ),
        );
      }
    }
  }

  Future<void> _confirmRestore(DriveBackupMetadata item) async {
    final auth = context.read<AuthProvider>();
    final notes = context.read<NotesProvider>();
    final backup = context.read<BackupProvider>();

    if (auth.googleUser == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.blue),
            SizedBox(width: 8),
            Text('Khôi phục ghi chú'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn đang chọn bản sao lưu:\n${item.name}'),
            const SizedBox(height: 8),
            Text(
              'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(item.createdTime)}\n'
              'Số ghi chú: ${item.noteCount > 0 ? item.noteCount : "N/A"}\n'
              'Dung lượng: ${item.formattedSize}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn cách khôi phục:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await backup.restoreBackup(
                account: auth.googleUser!,
                fileId: item.id,
                notesProvider: notes,
                overwrite: true,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Đã thay thế toàn bộ ghi chú từ bản sao lưu!'
                        : backup.errorMessage ?? 'Lỗi khôi phục'),
                  ),
                );
              }
            },
            child: const Text('Ghi đè tất cả'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await backup.restoreBackup(
                account: auth.googleUser!,
                fileId: item.id,
                notesProvider: notes,
                overwrite: false,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Đã gộp ghi chú từ bản sao lưu thành công!'
                        : backup.errorMessage ?? 'Lỗi khôi phục'),
                  ),
                );
              }
            },
            child: const Text('Gộp (Khuyên dùng)'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(DriveBackupMetadata item) async {
    final auth = context.read<AuthProvider>();
    final backup = context.read<BackupProvider>();

    if (auth.googleUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa bản sao lưu'),
        content: Text('Bạn có chắc chắn muốn xóa "${item.name}" khỏi Google Drive?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await backup.deleteBackup(account: auth.googleUser!, fileId: item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notes = context.watch<NotesProvider>();
    final backup = context.watch<BackupProvider>();
    final googleUser = auth.googleUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sao lưu Google Drive'),
        actions: [
          if (googleUser != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới danh sách',
              onPressed: backup.isLoadingList ? null : _loadBackups,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Thẻ tài khoản Google
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: googleUser?.photoUrl != null
                            ? NetworkImage(googleUser!.photoUrl!)
                            : null,
                        child: googleUser?.photoUrl == null
                            ? const Icon(Icons.account_circle, size: 36)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              googleUser?.displayName ?? (googleUser != null ? 'Tài khoản Google' : 'Chưa liên kết Google'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              googleUser?.email ?? 'Đăng nhập Google để kích hoạt sao lưu Drive cá nhân',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (googleUser != null)
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Đã sẵn sàng sao lưu vào Google Drive',
                          style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => auth.disconnectGoogleAccount(),
                          child: const Text('Đăng xuất Google', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('Kết nối tài khoản Google'),
                        onPressed: auth.isLoading ? null : _handleConnectGoogle,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Thao tác Sao lưu ngay
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sao lưu dữ liệu',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Chip(
                        label: Text('${notes.allNotes.length} ghi chú'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toàn bộ ghi chú, checklist, nhãn và màu sắc sẽ được đóng gói an toàn và lưu trữ trong thư mục riêng "T-Note Backups" trên Google Drive của bạn.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú mô tả (Tùy chọn)',
                      hintText: 'Ví dụ: Sao lưu trước khi đổi điện thoại...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: backup.isBackingUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        backup.isBackingUp ? 'Đang tải lên Google Drive...' : 'Sao lưu ngay lên Google Drive',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: (googleUser == null || backup.isBackingUp) ? null : _handleBackupNow,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Danh sách các bản sao lưu trên Drive
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LỊCH SỬ BẢN SAO LƯU (${backup.backups.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 1.1,
                ),
              ),
              if (backup.lastBackupDate != null)
                Text(
                  'Gần nhất: ${DateFormat('dd/MM HH:mm').format(backup.lastBackupDate!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (googleUser == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Hãy kết nối tài khoản Google để xem lịch sử sao lưu.'),
                    ],
                  ),
                ),
              ),
            )
          else if (backup.isLoadingList)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (backup.backups.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có bản sao lưu nào trên Google Drive.',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nhấn "Sao lưu ngay lên Google Drive" ở trên để tạo bản sao lưu đầu tiên!',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...backup.backups.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.file_present_outlined, color: Colors.deepPurple),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm:ss').format(item.createdTime),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'restore') {
                                _confirmRestore(item);
                              } else if (val == 'delete') {
                                _confirmDelete(item);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'restore',
                                child: Row(
                                  children: [
                                    Icon(Icons.restore, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Khôi phục ghi chú'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Xóa bản sao lưu', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '${item.noteCount > 0 ? item.noteCount : "?"} ghi chú',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              item.formattedSize,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Khôi phục'),
                            onPressed: backup.isRestoring ? null : () => _confirmRestore(item),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),

          // 4. Thông tin Bảo mật & Quyền riêng tư
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: Colors.blue, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bảo mật & Quyền riêng tư tuyệt đối',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ứng dụng chỉ sử dụng quyền "drive.file", nghĩa là chỉ có quyền đọc/ghi trên các tệp do T-Note tạo ra trong thư mục "T-Note Backups" trên Google Drive của bạn. Ứng dụng hoàn toàn KHÔNG THỂ xem, sửa hoặc xóa bất kỳ ảnh, tài liệu hoặc dữ liệu nào khác trên Google Drive của bạn.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
