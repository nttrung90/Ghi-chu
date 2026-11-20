import 'package:flutter/material.dart';

class AppColors {
  // Màu nhấn chính của ứng dụng (vàng hổ phách như trong thiết kế)
  static const Color accent = Color(0xFFFFC107);

  // Giữ tên cũ để các màn hình khác không bị ảnh hưởng
  static const Color primary = accent;
  static const Color secondary = Color(0xFF9E9E9E);

  // --- Bề mặt giao diện Tối (bám sát ảnh thiết kế) ---
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF171717);
  static const Color darkCard = Color(0xFF262626);
  static const Color darkCardAlt = Color(0xFF1C1C1C);
  static const Color darkChip = Color(0xFF2C2C2C);
  static const Color darkBorder = Color(0xFF3A3A3A);
  static const Color darkDivider = Color(0xFF242424);
  static const Color darkTextPrimary = Color(0xFFF3F3F3);
  static const Color darkTextSecondary = Color(0xFFA9A9A9);
  static const Color darkTextTertiary = Color(0xFF7C7C7C);

  // --- Bề mặt giao diện Sáng ---
  static const Color lightBackground = Color(0xFFF7F6F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightChip = Color(0xFFE9E5DC);
  static const Color lightBorder = Color(0xFFDDD8CE);
  static const Color lightDivider = Color(0xFFE6E1D8);
  static const Color lightTextPrimary = Color(0xFF1B1B1B);
  static const Color lightTextSecondary = Color(0xFF5E5E5E);
  static const Color lightTextTertiary = Color(0xFF8B8B8B);

  // Bảng màu pastel cho thẻ ghi chú
  static const List<Color> noteColorsLight = [
    Colors.white, // 0xFFFFFFFF
    Color(0xFFFFF8E1), // Vàng nhạt (Amber)
    Color(0xFFFFEBEE), // Đỏ/Hồng nhạt
    Color(0xFFE8F5E9), // Xanh lá cây nhạt
    Color(0xFFE3F2FD), // Xanh lam nhạt
    Color(0xFFEDE7F6), // Tím nhạt
    Color(0xFFFFF3E0), // Cam nhạt
    Color(0xFFF3E5F5), // Hồng tím
    Color(0xFFE0F7FA), // Xanh lơ (Cyan)
    Color(0xFFF5F5F5), // Xám bạc
  ];

  static const List<Color> noteColorsDark = [
    Color(0xFF262626), // Xám than mặc định
    Color(0xFF332B00), // Vàng đậm
    Color(0xFF3E1C1C), // Đỏ đậm
    Color(0xFF1C3322), // Xanh lá đậm
    Color(0xFF15293E), // Xanh lam đậm
    Color(0xFF261D36), // Tím đậm
    Color(0xFF3A2312), // Cam đậm
    Color(0xFF2C192E), // Hồng tím đậm
    Color(0xFF122E33), // Xanh lơ đậm
    Color(0xFF2D2D2D), // Xám than
  ];
}
