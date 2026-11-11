import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/checklist_item.dart';
import '../../../models/note_model.dart';
import '../../../providers/notes_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? initialNote;

  const NoteEditorScreen({super.key, this.initialNote});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagController;
  late final TextEditingController _checklistInputController;

  late String _id;
  late int _colorValue;
  late bool _isPinned;
  late bool _isArchived;
  late DateTime _createdAt;
  late List<ChecklistItem> _checklist;
  late List<String> _tags;

  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final note = widget.initialNote;
    _id = note?.id ?? const Uuid().v4();
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _tagController = TextEditingController();
    _checklistInputController = TextEditingController();

    _colorValue = note?.colorValue ?? 0xFFFFFFFF;
    _isPinned = note?.isPinned ?? false;
    _isArchived = note?.isArchived ?? false;
    _createdAt = note?.createdAt ?? DateTime.now();
    _checklist = note?.checklist.map((item) => item.copyWith()).toList() ?? [];
    _tags = List.from(note?.tags ?? []);

    _titleController.addListener(_markDirty);
    _contentController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _checklistInputController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Nếu không có nội dung, tiêu đề, checklist gì thì không lưu
    if (title.isEmpty && content.isEmpty && _checklist.isEmpty && widget.initialNote == null) {
      return;
    }

    final note = NoteModel(
      id: _id,
      title: title,
      content: content,
      checklist: _checklist,
      tags: _tags,
      colorValue: _colorValue,
      isPinned: _isPinned,
      isArchived: _isArchived,
      isDeleted: false,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );

    await context.read<NotesProvider>().saveNote(note);
    _isDirty = false;
  }

  void _addChecklistItem() {
    final text = _checklistInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklist.add(ChecklistItem(
          id: const Uuid().v4(),
          text: text,
          isDone: false,
        ));
        _checklistInputController.clear();
        _isDirty = true;
      });
    }
  }

  void _addTag(String tag) {
    final cleanTag = tag.trim().replaceAll('#', '');
    if (cleanTag.isNotEmpty && !_tags.contains(cleanTag)) {
      setState(() {
        _tags.add(cleanTag);
        _tagController.clear();
        _isDirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final palette = isDarkMode ? AppColors.noteColorsDark : AppColors.noteColorsLight;
    final backgroundColor = _colorValue == 0xFFFFFFFF
        ? (isDarkMode ? const Color(0xFF121212) : Colors.white)
        : Color(_colorValue);

    return CallbackShortcuts(
      bindings: {
        // Phím tắt Ctrl + S trên Windows
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          _saveNote();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu ghi chú!'), duration: Duration(seconds: 1)),
          );
        },
      },
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          if (_isDirty) {
            await _saveNote();
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: _isPinned ? AppStrings.unpin : AppStrings.pin,
                icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                onPressed: () {
                  setState(() {
                    _isPinned = !_isPinned;
                    _isDirty = true;
                  });
                },
              ),
              if (widget.initialNote != null)
                IconButton(
                  tooltip: AppStrings.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final notesProvider = context.read<NotesProvider>();
                    final navigator = Navigator.of(context);
                    await notesProvider.moveToTrash(_id);
                    if (mounted) navigator.pop();
                  },
                ),
              IconButton(
                tooltip: 'Lưu',
                icon: const Icon(Icons.check),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await _saveNote();
                  if (mounted) navigator.pop();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    // Tiêu đề ghi chú
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: AppStrings.titleHint,
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 10),

                    // Nội dung ghi chú
                    TextField(
                      controller: _contentController,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: AppStrings.contentHint,
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),

                    const SizedBox(height: 20),

                    // Phần danh sách Checklist
                    if (_checklist.isNotEmpty) ...[
                      const Divider(),
                      const Text(
                        'Danh sách việc cần làm',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ..._checklist.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Row(
                          children: [
                            Checkbox(
                              value: item.isDone,
                              onChanged: (val) {
                                setState(() {
                                  item.isDone = val ?? false;
                                  _isDirty = true;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                item.text,
                                style: TextStyle(
                                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                                  color: item.isDone ? Colors.grey : null,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _checklist.removeAt(index);
                                  _isDirty = true;
                                });
                              },
                            ),
                          ],
                        );
                      }),
                    ],

                    // Ô nhập thêm checklist mới
                    Row(
                      children: [
                        const Icon(Icons.add_box_outlined, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _checklistInputController,
                            decoration: const InputDecoration(
                              hintText: AppStrings.addChecklistItem,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _addChecklistItem(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _addChecklistItem,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Thẻ nhãn (Tags)
                    if (_tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text('#$tag'),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _tags.remove(tag);
                                _isDirty = true;
                              });
                            },
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 8),

                    // Thêm Tag mới
                    Row(
                      children: [
                        const Icon(Icons.label_outline, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _tagController,
                            decoration: const InputDecoration(
                              hintText: 'Thêm thẻ...',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (tag) => _addTag(tag),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _addTag(_tagController.text),
                          child: const Text('Thêm'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Thanh công cụ chọn màu nền phía dưới
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                  border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                ),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: palette.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final color = palette[index];
                      final isSelected = _colorValue == color.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _colorValue = color.toARGB32();
                            _isDirty = true;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check, size: 18, color: Theme.of(context).primaryColor)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
