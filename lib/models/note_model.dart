import 'dart:convert';
import 'checklist_item.dart';

/// Đại diện cho một bản ghi chú đầy đủ trong ứng dụng Note NTT
class NoteModel {
  final String id;
  final String title;
  final String content;
  final List<ChecklistItem> checklist;
  final List<String> tags;
  final int colorValue; // Mã màu hex (ARGB)
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted; // Soft delete - chuyển vào thùng rác
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced; // Đánh dấu đã đồng bộ với Firebase

  NoteModel({
    required this.id,
    this.title = '',
    this.content = '',
    this.checklist = const [],
    this.tags = const [],
    this.colorValue = 0xFFFFFFFF, // Mặc định màu trắng
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    List<ChecklistItem>? checklist,
    List<String>? tags,
    int? colorValue,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      checklist: checklist ?? this.checklist,
      tags: tags ?? this.tags,
      colorValue: colorValue ?? this.colorValue,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'tags': tags,
      'colorValue': colorValue,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      checklist: (map['checklist'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      tags: (map['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
      colorValue: map['colorValue'] ?? 0xFFFFFFFF,
      isPinned: map['isPinned'] ?? false,
      isArchived: map['isArchived'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      isSynced: true,
    );
  }

  String toJson() => json.encode(toMap());

  factory NoteModel.fromJson(String source) => NoteModel.fromMap(json.decode(source));
}
