import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../models/checklist_item.dart';
import '../../../models/note_model.dart';
import '../../../providers/app_update_provider.dart';
import '../../../providers/notes_provider.dart';
import '../../../services/app_update_service.dart';
import '../editor/note_editor_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/widgets/app_update_dialog.dart';
import 'widgets/drawer_menu.dart';
import 'widgets/note_card.dart';

enum _HomeTab { notes, tasks }

enum _TaskFilter { all, pending, completed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  _HomeTab _tab = _HomeTab.notes;
  _TaskFilter _taskFilter = _TaskFilter.all;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkForUpdatesOnStartup();
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _createNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
    );
  }

  void _openEditor(NoteModel note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(initialNote: note)),
    );
  }

  void _switchTab(_HomeTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  void _openSearch() {
    if (_isSearching) {
      _searchFocusNode.requestFocus();
      return;
    }
    setState(() => _isSearching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    if (!_isSearching) return;
    _searchController.clear();
    context.read<NotesProvider>().setSearchQuery('');
    _searchFocusNode.unfocus();
    setState(() => _isSearching = false);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _checkForUpdatesOnStartup() async {
    final updateProvider = context.read<AppUpdateProvider>();
    final result = await updateProvider.autoCheckForUpdate();
    if (!mounted ||
        result.status != AppUpdateCheckStatus.updateAvailable ||
        result.info == null ||
        !result.shouldNotify) {
      return;
    }

    // Không chèn hộp thoại lên màn hình khác nếu người dùng đã điều hướng.
    if (ModalRoute.of(context)?.isCurrent != true) return;

    await showAppUpdateDialog(
      context: context,
      provider: updateProvider,
      info: result.info!,
      automatic: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final isDesktop = PlatformUtils.isTabletOrDesktop(context);
    final notes = <NoteModel>[
      ...notesProvider.pinnedNotes,
      ...notesProvider.unpinnedNotes,
    ];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _createNewNote,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _openSearch,
        const SingleActivator(LogicalKeyboardKey.escape): _closeSearch,
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: isDesktop
            ? null
            : DrawerMenu(
                embedded: false,
                isNotesActive: _tab == _HomeTab.notes,
                isTasksActive: _tab == _HomeTab.tasks,
                onOpenNotes: () => _switchTab(_HomeTab.notes),
                onOpenTasks: () => _switchTab(_HomeTab.tasks),
              ),
        body: Row(
          children: [
            // Sidebar cố định trên màn hình rộng
            if (isDesktop)
              SizedBox(
                width: 270,
                child: DrawerMenu(
                  embedded: true,
                  isNotesActive: _tab == _HomeTab.notes,
                  isTasksActive: _tab == _HomeTab.tasks,
                  onOpenNotes: () => _switchTab(_HomeTab.notes),
                  onOpenTasks: () => _switchTab(_HomeTab.tasks),
                ),
              ),

            Expanded(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildHeader(context, isDesktop),
                    _buildFilterRow(context, notesProvider),
                    Expanded(
                      child: _tab == _HomeTab.notes
                          ? _buildNotesGrid(context, notes, notesProvider)
                          : _buildTasksView(context, notesProvider),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: isDesktop ? null : _buildBottomNavigation(context),
        floatingActionButton:
            _tab == _HomeTab.notes ? _buildFloatingButton() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header & bộ lọc
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = _tab == _HomeTab.notes ? AppStrings.notes : AppStrings.tasks;

    return SizedBox(
      height: 64,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _isSearching
            ? Padding(
                key: const ValueKey('search-field'),
                padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) {
                          context.read<NotesProvider>().setSearchQuery(value);
                          setState(() {});
                        },
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: AppStrings.searchNotesHint,
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 21),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Xóa từ khóa',
                                  icon:
                                      const Icon(Icons.close_rounded, size: 19),
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<NotesProvider>()
                                        .setSearchQuery('');
                                    setState(() {});
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Đóng tìm kiếm',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _closeSearch,
                    ),
                  ],
                ),
              )
            : SizedBox(
                key: const ValueKey('header-title'),
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Positioned(
                      left: 4,
                      child: IconButton(
                        tooltip: 'Tìm kiếm',
                        icon: const Icon(Icons.search_rounded, size: 25),
                        onPressed: _openSearch,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isDesktop)
                            IconButton(
                              tooltip: 'Thư mục & nhãn',
                              icon: const Icon(Icons.folder_outlined, size: 25),
                              onPressed: _openDrawer,
                            ),
                          IconButton(
                            tooltip: 'Cài đặt',
                            icon: const Icon(Icons.settings_outlined, size: 25),
                            onPressed: _openSettings,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, NotesProvider provider) {
    final List<_FilterData> filters;

    if (_tab == _HomeTab.notes) {
      final tags = provider.allTags.toList()..sort();
      filters = [
        _FilterData(
          label: AppStrings.allFilter,
          selected: provider.selectedTag == null && !provider.showUncategorized,
          onTap: provider.showAllNotes,
        ),
        ...tags.map(
          (tag) => _FilterData(
            label: tag,
            selected: provider.selectedTag == tag,
            onTap: () => provider.setSelectedTag(
              provider.selectedTag == tag ? null : tag,
            ),
          ),
        ),
        if (provider.hasUncategorizedNotes)
          _FilterData(
            label: AppStrings.uncategorized,
            selected: provider.showUncategorized,
            onTap: () => provider.setUncategorizedOnly(
              !provider.showUncategorized,
            ),
          ),
      ];
    } else {
      filters = [
        _FilterData(
          label: AppStrings.allFilter,
          selected: _taskFilter == _TaskFilter.all,
          onTap: () => setState(() => _taskFilter = _TaskFilter.all),
        ),
        _FilterData(
          label: 'Chưa xong',
          selected: _taskFilter == _TaskFilter.pending,
          onTap: () => setState(() => _taskFilter = _TaskFilter.pending),
        ),
        _FilterData(
          label: 'Đã xong',
          selected: _taskFilter == _TaskFilter.completed,
          onTap: () => setState(() => _taskFilter = _TaskFilter.completed),
        ),
      ];
    }

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return _FilterPill(
            label: filter.label,
            selected: filter.selected,
            onTap: filter.onTap,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Danh sách ghi chú
  // ---------------------------------------------------------------------------

  Widget _buildNotesGrid(
    BuildContext context,
    List<NoteModel> notes,
    NotesProvider provider,
  ) {
    if (notes.isEmpty) {
      return _EmptyNotesState(
        isSearching: provider.searchQuery.isNotEmpty,
        onCreate: _createNewNote,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            PlatformUtils.getGridColumnCountForWidth(constraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: MasonryGridView.count(
              padding: EdgeInsets.fromLTRB(
                14,
                2,
                14,
                120 + MediaQuery.paddingOf(context).bottom,
              ),
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return NoteCard(
                  note: note,
                  onTap: () => _openEditor(note),
                  onTogglePin: () => provider.togglePin(note.id),
                  onLongPress: () => _showNoteActions(note),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tab nhiệm vụ
  // ---------------------------------------------------------------------------

  Widget _buildTasksView(BuildContext context, NotesProvider provider) {
    final entries = <_TaskEntry>[];
    for (final note in provider.searchFilteredActiveNotes) {
      for (final item in note.checklist) {
        entries.add(_TaskEntry(note: note, item: item));
      }
    }

    if (entries.isEmpty) {
      return const _EmptyTasksState();
    }

    entries.sort((a, b) {
      if (a.item.isDone == b.item.isDone) {
        return b.note.updatedAt.compareTo(a.note.updatedAt);
      }
      return a.item.isDone ? 1 : -1;
    });

    final total = entries.length;
    final done = entries.where((entry) => entry.item.isDone).length;
    final filtered = entries.where((entry) {
      switch (_taskFilter) {
        case _TaskFilter.all:
          return true;
        case _TaskFilter.pending:
          return !entry.item.isDone;
        case _TaskFilter.completed:
          return entry.item.isDone;
      }
    }).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        14,
        2,
        14,
        120 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _TaskSummaryCard(total: total, done: done),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Text(
              _taskFilter == _TaskFilter.pending
                  ? 'Bạn đã hoàn thành tất cả nhiệm vụ!'
                  : 'Chưa có nhiệm vụ nào trong mục này.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
          )
        else
          ...filtered.map(
            (entry) => _TaskTile(
              entry: entry,
              onToggle: () => provider.toggleChecklistItem(
                entry.note.id,
                entry.item.id,
              ),
              onOpen: () => _openEditor(entry.note),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom navigation & FAB
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : theme.colorScheme.outlineVariant,
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.notes_rounded,
                  label: AppStrings.notes,
                  selected: _tab == _HomeTab.notes,
                  onTap: () => _switchTab(_HomeTab.notes),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.check_box_outlined,
                  label: AppStrings.tasks,
                  selected: _tab == _HomeTab.tasks,
                  onTap: () => _switchTab(_HomeTab.tasks),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return SizedBox(
      width: 64,
      height: 64,
      child: FloatingActionButton(
        heroTag: 'home-new-note-fab',
        onPressed: _createNewNote,
        tooltip: 'Ghi chú mới',
        child: const Icon(Icons.add_rounded, size: 34, color: Colors.white),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Thao tác ghi chú
  // ---------------------------------------------------------------------------

  void _showNoteActions(NoteModel note) {
    final provider = context.read<NotesProvider>();

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  note.title.trim().isEmpty
                      ? 'Không có tiêu đề'
                      : note.title.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  note.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                ),
                title: Text(
                  note.isPinned ? AppStrings.unpin : AppStrings.pin,
                ),
                onTap: () {
                  provider.togglePin(note.id);
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Chỉnh sửa ghi chú'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openEditor(note);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Chuyển vào thùng rác',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  provider.moveToTrash(note.id);
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Widget phụ trợ
// -----------------------------------------------------------------------------

class _FilterData {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterData({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedBackground =
        isDark ? AppColors.darkChip : AppColors.lightChip;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final selectedText =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final unselectedText =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: selected ? selectedBackground : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? selectedBackground : borderColor,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? selectedText : unselectedText,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.onSurface;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.42);

    return InkResponse(
      onTap: onTap,
      radius: 42,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: selected ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotesState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onCreate;

  const _EmptyNotesState({
    required this.isSearching,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? Icons.search_off_rounded : Icons.note_alt_outlined,
              size: 64,
              color: muted,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? AppStrings.emptySearch : AppStrings.emptyNotes,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5, color: muted),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo ghi chú'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  const _EmptyTasksState();

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rounded, size: 64, color: muted),
            const SizedBox(height: 16),
            Text(
              AppStrings.emptyTasks,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskEntry {
  final NoteModel note;
  final ChecklistItem item;

  const _TaskEntry({required this.note, required this.item});
}

class _TaskSummaryCard extends StatelessWidget {
  final int total;
  final int done;

  const _TaskSummaryCard({required this.total, required this.done});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : theme.colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$done/$total việc đã hoàn thành',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outlineVariant,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            total - done == 0
                ? 'Mọi việc đã xong. Tuyệt vời!'
                : '${total - done} việc còn lại',
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final _TaskEntry entry;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  const _TaskTile({
    required this.entry,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = entry.item.isDone;
    final titleColor = theme.colorScheme.onSurface;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.52);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
            child: Row(
              children: [
                InkResponse(
                  onTap: onToggle,
                  radius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 24,
                      color: isDone
                          ? theme.colorScheme.primary
                          : (isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.item.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          color: isDone ? muted : titleColor,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.note.title.trim().isEmpty
                            ? 'Không có tiêu đề'
                            : entry.note.title.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
