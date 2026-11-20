import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notes_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../settings/google_drive_backup_screen.dart';
import '../../settings/settings_screen.dart';
import '../../trash/trash_screen.dart';

class DrawerMenu extends StatelessWidget {
  /// Khi được nhúng trực tiếp vào sidebar trên desktop, không dùng Navigator.pop.
  final bool embedded;
  final bool isNotesActive;
  final bool isTasksActive;
  final VoidCallback? onOpenNotes;
  final VoidCallback? onOpenTasks;

  const DrawerMenu({
    super.key,
    this.embedded = false,
    this.isNotesActive = false,
    this.isTasksActive = false,
    this.onOpenNotes,
    this.onOpenTasks,
  });

  void _closeIfNeeded(BuildContext context) {
    if (!embedded) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;

    final content = SafeArea(
      child: Column(
        children: [
          // Thông tin ứng dụng & tài khoản
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 0.8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFF241A00),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.appName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Ghi chú & nhiệm vụ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.16),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Icon(
                              authProvider.isAuthenticated
                                  ? Icons.person_rounded
                                  : Icons.person_outline_rounded,
                              size: 17,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        user?.displayName ??
                            user?.email ??
                            (authProvider.isAnonymous
                                ? 'Khách (Anonymous)'
                                : 'Chưa đăng nhập'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Điều hướng chính
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              children: [
                _navTile(
                  context,
                  icon: Icons.notes_rounded,
                  title: AppStrings.allNotes,
                  trailing: '${notesProvider.activeNotesCount}',
                  selected: isNotesActive &&
                      notesProvider.selectedTag == null &&
                      !notesProvider.showUncategorized,
                  onTap: () {
                    notesProvider.showAllNotes();
                    _closeIfNeeded(context);
                    onOpenNotes?.call();
                  },
                ),
                _navTile(
                  context,
                  icon: Icons.checklist_rounded,
                  title: AppStrings.tasks,
                  trailingBadge: notesProvider.pendingChecklistItems > 0
                      ? '${notesProvider.pendingChecklistItems}'
                      : null,
                  selected: isTasksActive,
                  onTap: () {
                    _closeIfNeeded(context);
                    onOpenTasks?.call();
                  },
                ),
                const SizedBox(height: 4),
                Divider(
                  color: theme.dividerColor,
                  height: 16,
                  indent: 12,
                  endIndent: 12,
                ),
                _navTile(
                  context,
                  icon: Icons.delete_outline_rounded,
                  title: AppStrings.trash,
                  trailing: '${notesProvider.trashNotes.length}',
                  onTap: () {
                    _closeIfNeeded(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrashScreen(),
                      ),
                    );
                  },
                ),
                _navTile(
                  context,
                  icon: Icons.add_to_drive_rounded,
                  iconColor: Colors.greenAccent.shade400,
                  title: AppStrings.googleDriveBackup,
                  onTap: () {
                    _closeIfNeeded(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GoogleDriveBackupScreen(),
                      ),
                    );
                  },
                ),
                _navTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: AppStrings.settings,
                  onTap: () {
                    _closeIfNeeded(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                // Danh sách nhãn
                if (notesProvider.allTags.isNotEmpty ||
                    notesProvider.hasUncategorizedNotes) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                    child: Text(
                      AppStrings.tags.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.38),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...(notesProvider.allTags.toList()..sort()).map((tag) {
                    final isSelected = notesProvider.selectedTag == tag;
                    return _navTile(
                      context,
                      icon: Icons.label_outline_rounded,
                      title: '#$tag',
                      selected: isSelected,
                      onTap: () {
                        notesProvider.setSelectedTag(
                          isSelected ? null : tag,
                        );
                        _closeIfNeeded(context);
                        onOpenNotes?.call();
                      },
                    );
                  }),
                  if (notesProvider.hasUncategorizedNotes)
                    _navTile(
                      context,
                      icon: Icons.label_off_outlined,
                      title: AppStrings.uncategorized,
                      selected: notesProvider.showUncategorized,
                      onTap: () {
                        notesProvider.setUncategorizedOnly(
                          !notesProvider.showUncategorized,
                        );
                        _closeIfNeeded(context);
                        onOpenNotes?.call();
                      },
                    ),
                ],
              ],
            ),
          ),

          Divider(color: theme.dividerColor, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              children: [
                Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  size: 21,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    themeProvider.isDarkMode ? 'Chế độ tối' : 'Chế độ sáng',
                    style: TextStyle(
                      fontSize: 13.5,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: themeProvider.isDarkMode,
                  activeTrackColor: AppColors.accent,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          border: Border(
            right: BorderSide(color: theme.dividerColor, width: 0.8),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: content,
        ),
      );
    }

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: content,
    );
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailing,
    String? trailingBadge,
    bool selected = false,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          size: 21,
          color: selected
              ? theme.colorScheme.primary
              : (iconColor ??
                  theme.colorScheme.onSurface.withValues(alpha: 0.62)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        trailing: trailingBadge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailingBadge,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF241A00),
                  ),
                ),
              )
            : (trailing != null
                ? Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.42),
                    ),
                  )
                : null),
        selected: selected,
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.10),
        onTap: onTap,
      ),
    );
  }
}
