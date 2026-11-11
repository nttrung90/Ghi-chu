import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notes_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../trash/trash_screen.dart';
import '../../settings/settings_screen.dart';
import '../../settings/google_drive_backup_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final user = authProvider.user;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Tiêu đề App & Thông tin tài khoản
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.appName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Firebase & Drive Sync',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Thông tin người dùng
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null
                            ? Icon(
                                authProvider.isAuthenticated ? Icons.person : Icons.person_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user?.displayName ??
                              user?.email ??
                              (authProvider.isAnonymous ? "Khách (Anonymous)" : "Chưa đăng nhập"),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Danh sách các mục điều hướng
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: const Text(AppStrings.allNotes),
                    trailing: Text(
                      '${notesProvider.filteredActiveNotes.length}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    selected: notesProvider.selectedTag == null,
                    onTap: () {
                      notesProvider.setSelectedTag(null);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text(AppStrings.trash),
                    trailing: Text(
                      '${notesProvider.trashNotes.length}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TrashScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_to_drive, color: Colors.green),
                    title: const Text('Sao lưu Google Drive'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GoogleDriveBackupScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text(AppStrings.settings),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),

                  const Divider(),

                  // Danh sách các Thẻ nhãn (Tags)
                  if (notesProvider.allTags.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        AppStrings.tags.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...notesProvider.allTags.map((tag) {
                      final isSelected = notesProvider.selectedTag == tag;
                      return ListTile(
                        leading: const Icon(Icons.label_outline, size: 20),
                        title: Text('#$tag'),
                        selected: isSelected,
                        onTap: () {
                          notesProvider.setSelectedTag(isSelected ? null : tag);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),

            const Divider(),

            // Chuyển đổi Dark / Light Theme
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, size: 20),
                      const SizedBox(width: 12),
                      Text(isDarkMode ? 'Chế độ Tối' : 'Chế độ Sáng'),
                    ],
                  ),
                  Switch(
                    value: isDarkMode,
                    onChanged: (val) => themeProvider.toggleTheme(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
