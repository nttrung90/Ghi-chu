import 'package:intl/intl.dart';

class DateFormatter {
  /// Trả về chuỗi ngày thân thiện (Hôm nay, Hôm qua, hoặc ngày tháng)
  static String formatFriendly(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24 && date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1 || (difference.inHours < 48 && date.day == now.day - 1)) {
      return 'Hôm qua ${DateFormat('HH:mm').format(date)}';
    } else if (date.year == now.year) {
      return DateFormat('d MMM, HH:mm', 'vi').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
