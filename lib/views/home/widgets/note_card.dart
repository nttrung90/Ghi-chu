import 'package:flutter/material.dart';
import '../../../models/note_model.dart';
import '../../../core/utils/date_formatter.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Color(note.colorValue);

    // Tính toán độ tương phản chữ nếu nền sáng/tối
    final isCardWhite = cardColor.value == 0xFFFFFFFF;
    final backgroundColor = isCardWhite
        ? (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
        : cardColor;

    final textColor = isDarkMode && isCardWhite ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hàng tiêu đề & nút Ghim
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isNotEmpty ? note.title : 'Không có tiêu đề',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: note.title.isNotEmpty ? textColor : Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: note.isPinned ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                      onPressed: onTogglePin,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Nội dung văn bản
                if (note.content.isNotEmpty)
                  Text(
                    note.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                      height: 1.35,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Xem trước Checklist việc cần làm
                if (note.checklist.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...note.checklist.take(3).map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Icon(
                            item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                            size: 16,
                            color: item.isDone ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: item.isDone ? Colors.grey : textColor,
                                decoration: item.isDone ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (note.checklist.length > 3)
                    Text(
                      '+ ${note.checklist.length - 3} việc khác...',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],

                // Thẻ nhãn (Tags)
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: note.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7)),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 10),

                // Thời gian cập nhật & Icon đồng bộ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatFriendly(note.updatedAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    Icon(
                      note.isSynced ? Icons.cloud_done_outlined : Icons.cloud_queue_outlined,
                      size: 14,
                      color: note.isSynced ? Colors.green.shade400 : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
