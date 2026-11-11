import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notes_provider.dart';
import '../../../providers/theme_provider.dart';
import '../auth/login_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notes = context.watch<NotesProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          // Mục tài khoản & Firebase Cloud
          ListTile(
            title: const Text('Tài khoản & Đồng bộ Đám mây (Firebase)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Icon(
                auth.isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              auth.isAuthenticated
                  ? (auth.user?.email ?? 'Chế độ Khách (Anonymous)')
                  : 'Chưa kết nối tài khoản Firebase',
            ),
            subtitle: Text(
              auth.isAuthenticated
                  ? 'Đang tự động đồng bộ giữa Android, iOS và Windows'
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

          // Mục Giao diện
          const ListTile(
            title: Text('Giao diện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Theo hệ thống'),
            value: ThemeMode.system,
            groupValue: theme.themeMode,
            onChanged: (mode) => theme.setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Chế độ Sáng'),
            value: ThemeMode.light,
            groupValue: theme.themeMode,
            onChanged: (mode) => theme.setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Chế độ Tối'),
            value: ThemeMode.dark,
            groupValue: theme.themeMode,
            onChanged: (mode) => theme.setThemeMode(mode!),
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
