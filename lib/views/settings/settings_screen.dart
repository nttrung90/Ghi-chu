import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/backup_provider.dart';
import '../../../providers/notes_provider.dart';
import '../../../providers/theme_provider.dart';
import '../auth/login_dialog.dart';
import 'google_drive_backup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notes = context.watch<NotesProvider>();
    final theme = context.watch<ThemeProvider>();
    final backup = context.watch<BackupProvider>();

    final user = auth.user;
    final googleUser = auth.googleUser;
    final isGoogle = auth.isGoogleSignedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          // Mục tài khoản & Firebase Cloud
          const ListTile(
            title: Text('Tài khoản & Đồng bộ Đám mây (Firebase)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? Icon(
                      auth.isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    auth.isAuthenticated
                        ? (user?.displayName ?? user?.email ?? 'Chế độ Khách (Anonymous)')
                        : 'Chưa kết nối tài khoản Firebase',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (isGoogle)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Google', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Text(
              auth.isAuthenticated
                  ? (user?.email != null && user?.displayName != null
                      ? '${user?.email}\nĐang tự động đồng bộ thời gian thực'
                      : 'Đang tự động đồng bộ giữa Android, iOS và Windows')
                  : 'Đăng nhập để tự động sao lưu và đồng bộ',
            ),
            trailing: ElevatedButton(
              onPressed: () {
                if (auth.isAuthenticated) {
                  auth.signOut();
                  notes.updateUserId(null);
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => const LoginDialog(),
                  );
                }
              },
              child: Text(auth.isAuthenticated ? 'Đăng xuất' : 'Đăng nhập'),
            ),
          ),

          const Divider(),

          // Mục Sao lưu Google Drive
          const ListTile(
            title: Text('Sao lưu & Khôi phục (Google Drive cá nhân)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.15),
              child: const Icon(Icons.add_to_drive, color: Colors.green),
            ),
            title: const Text('Sao lưu lên Google Drive'),
            subtitle: Text(
              googleUser != null
                  ? 'Đã kết nối: ${googleUser.email}${backup.backups.isNotEmpty ? ' (${backup.backups.length} bản sao lưu)' : ''}'
                  : 'Lưu trữ tệp sao lưu an toàn vào Google Drive của chính bạn',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoogleDriveBackupScreen()),
              );
            },
          ),

          const Divider(),

          // Mục Giao diện
          const ListTile(
            title: Text('Giao diện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          RadioGroup<ThemeMode>(
            groupValue: theme.themeMode,
            onChanged: (mode) {
              if (mode != null) theme.setThemeMode(mode);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('Theo hệ thống'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Chế độ Sáng'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Chế độ Tối'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),

          const Divider(),

          // Mục Thông tin ứng dụng
          const ListTile(
            title: Text('Thông tin ứng dụng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppStrings.appName),
            subtitle: Text('Phiên bản 0.1.0+1 (Build 1)'),
          ),
          const ListTile(
            leading: Icon(Icons.offline_bolt_outlined),
            title: Text('Kiến trúc Offline-First'),
            subtitle: Text('Ghi chú hoạt động ngay lập tức không cần mạng, tự động đồng bộ khi có kết nối.'),
          ),
        ],
      ),
    );
  }
}
