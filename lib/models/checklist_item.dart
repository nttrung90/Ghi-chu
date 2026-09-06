/// Đại diện cho một mục việc cần làm (Checklist Item) trong một ghi chú
class ChecklistItem {
  final String id;
  String text;
  bool isDone;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isDone': isDone,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isDone: map['isDone'] ?? false,
    );
  }

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isDone,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }
}
