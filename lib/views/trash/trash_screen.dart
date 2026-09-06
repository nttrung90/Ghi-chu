import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/notes_provider.dart';
import '../home/widgets/note_card.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final trashNotes = notesProvider.trashNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.trash),
        actions: [
          if (trashNotes.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Dọn sạch', style: TextStyle(color: Colors.red)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Dọn sạch thùng rác?'),
                    content: const Text(
                      'Tất cả ghi chú trong thùng rác sẽ bị xóa vĩnh viễn và không thể khôi phục.',
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Hủy'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      TextButton(
                        child: const Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          notesProvider.emptyTrash();
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: trashNotes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(AppStrings.emptyTrash, style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trashNotes.length,
              itemBuilder: (context, index) {
                final note = trashNotes[index];
                return Dismissible(
                  key: Key(note.id),
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.restore, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    if (direction == DismissDirection.startToEnd) {
                      notesProvider.restoreFromTrash(note.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã khôi phục ghi chú')),
                      );
                    } else {
                      notesProvider.deleteForever(note.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa vĩnh viễn')),
                      );
                    }
                  },
                  child: NoteCard(
                    note: note,
                    onTap: () {
                      _showActionSheet(context, notesProvider, note.id);
                    },
                    onTogglePin: () {},
                  ),
                );
              },
            ),
    );
  }

  void _showActionSheet(BuildContext context, NotesProvider provider, String noteId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.green),
              title: const Text('Khôi phục ghi chú'),
              onTap: () {
                provider.restoreFromTrash(noteId);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Xóa vĩnh viễn'),
              onTap: () {
                provider.deleteForever(noteId);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
