import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onTogglePin,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    final noteColor = Color(note.colorValue);
    final isDefaultColor = note.colorValue == 0xFFFFFFFF;

    // Thẻ mặc định dùng màu bề mặt của theme. Các màu pastel được làm tối
    // trong chế độ tối để vẫn giữ được độ tương phản với chữ trắng.
    final backgroundColor = isDefaultColor
        ? theme.cardColor
        : (isDark
            ? Color.alphaBlend(
                Colors.black.withValues(alpha: 0.64),
                noteColor,
              )
            : noteColor);

    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final bodyColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dateColor =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: isDark
          ? BorderSide(
              color: Colors.white.withValues(alpha: 0.035),
              width: 0.8,
            )
          : BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.9),
              width: 0.8,
            ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: backgroundColor,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.title.trim().isNotEmpty)
                  Text(
                    note.title.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: titleColor,
                    ),
                  ),

                if (note.title.trim().isNotEmpty &&
                    (note.content.trim().isNotEmpty ||
                        note.checklist.isNotEmpty))
                  const SizedBox(height: 9),

                if (note.content.trim().isNotEmpty)
                  Text(
                    note.content.trim(),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: bodyColor,
                    ),
                  ),

                // Xem trước danh sách việc cần làm
                if (note.checklist.isNotEmpty) ...[
                  if (note.content.trim().isNotEmpty)
                    const SizedBox(height: 10),
                  ...note.checklist.take(3).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(
                                  item.isDone
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: 16,
                                  color: item.isDone
                                      ? theme.colorScheme.primary
                                      : dateColor,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  item.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: item.isDone ? dateColor : bodyColor,
                                    decoration: item.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (note.checklist.length > 3)
                    Text(
                      '+ ${note.checklist.length - 3} việc khác',
                      style: TextStyle(
                        fontSize: 12,
                        color: dateColor,
                      ),
                    ),
                ],

                // Nhãn của ghi chú
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: note.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.055)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 11,
                            color: bodyColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),

                // Ngày cập nhật & biểu tượng ghim
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormatter.formatNoteCardDate(note.updatedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: dateColor,
                        ),
                      ),
                    ),
                    if (note.isPinned)
                      GestureDetector(
                        onTap: onTogglePin,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 15,
                            color: dateColor,
                          ),
                        ),
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
