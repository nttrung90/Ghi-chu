import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../models/note_model.dart';
import '../../../providers/notes_provider.dart';
import '../editor/note_editor_screen.dart';
import 'widgets/drawer_menu.dart';
import 'widgets/note_card.dart';
import 'widgets/sync_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final isDesktop = PlatformUtils.isTabletOrDesktop(context);
    final pinnedNotes = notesProvider.pinnedNotes;
    final unpinnedNotes = notesProvider.unpinnedNotes;

    // Thiết lập phím tắt máy tính (Windows Desktop)
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _createNewNote,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          _searchFocusNode.requestFocus();
        },
      },
      child: Scaffold(
        drawer: isDesktop ? null : const DrawerMenu(),
        body: Row(
          children: [
            // Trên Desktop/Windows: Hiển thị thanh Sidebar cố định bên trái
            if (isDesktop)
              const SizedBox(
                width: 260,
                child: DrawerMenu(),
              ),

            // Khu vực nội dung chính
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // App Bar với thanh tìm kiếm và biểu tượng đồng bộ
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    title: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        focusNode: _searchFocusNode,
                        controller: _searchController,
                        onChanged: (val) => notesProvider.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: AppStrings.searchNotesHint,
                          hintStyle: const TextStyle(fontSize: 14),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    notesProvider.setSearchQuery('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    actions: const [
                      Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: Center(child: SyncIndicator()),
                      ),
                    ],
                  ),

                  // Thanh lọc Tag được chọn (nếu có)
                  if (notesProvider.selectedTag != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Chip(
                              avatar: const Icon(Icons.label, size: 16),
                              label: Text('#${notesProvider.selectedTag}'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => notesProvider.setSelectedTag(null),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Khi không có ghi chú nào
                  if (pinnedNotes.isEmpty && unpinnedNotes.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 72, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              AppStrings.emptyNotes,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Mục "Đã ghim" (Pinned Notes)
                  if (pinnedNotes.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          AppStrings.pinnedNotes,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    _buildNoteGrid(context, pinnedNotes, notesProvider),
                  ],

                  // Mục "Khác" (Các ghi chú thông thường)
                  if (unpinnedNotes.isNotEmpty) ...[
                    if (pinnedNotes.isNotEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            AppStrings.otherNotes,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    _buildNoteGrid(context, unpinnedNotes, notesProvider),
                  ],

                  // Đệm dưới để không bị che bởi FAB
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createNewNote,
          icon: const Icon(Icons.add),
          label: const Text('Ghi chú mới'),
        ),
      ),
    );
  }

  Widget _buildNoteGrid(
    BuildContext context,
    List<NoteModel> notes,
    NotesProvider provider,
  ) {
    final columns = PlatformUtils.getGridColumnCount(context);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 1.1,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final note = notes[index];
            return NoteCard(
              note: note,
              onTap: () => _openEditor(note),
              onTogglePin: () => provider.togglePin(note.id),
            );
          },
          childCount: notes.length,
        ),
      ),
    );
  }
}
