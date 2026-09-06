import 'package:flutter/material.dart';

class AppColors {
  // Màu chủ đạo của Note NTT
  static const Color primary = Color(0xFF6750A4);
  static const Color secondary = Color(0xFF625B71);

  // Bảng màu pastel cho thẻ ghi chú
  static const List<Color> noteColorsLight = [
    Colors.white,             // 0xFFFFFFFF
    Color(0xFFFFF8E1),        // Vàng nhạt (Amber)
    Color(0xFFFFEBEE),        // Đỏ/Hồng nhạt
    Color(0xFFE8F5E9),        // Xanh lá cây nhạt
    Color(0xFFE3F2FD),        // Xanh lam nhạt
    Color(0xFFEDE7F6),        // Tím nhạt
    Color(0xFFFFF3E0),        // Cam nhạt
    Color(0xFFF3E5F5),        // Hồng tím
    Color(0xFFE0F7FA),        // Xanh lơ (Cyan)
    Color(0xFFF5F5F5),        // Xám bạc
  ];

  static const List<Color> noteColorsDark = [
    Color(0xFF1E1E1E),        // Đen xám mặc định
    Color(0xFF332B00),        // Vàng đậm
    Color(0xFF3E1C1C),        // Đỏ đậm
    Color(0xFF1C3322),        // Xanh lá đậm
    Color(0xFF15293E),        // Xanh lam đậm
    Color(0xFF261D36),        // Tím đậm
    Color(0xFF3A2312),        // Cam đậm
    Color(0xFF2C192E),        // Hồng tím đậm
    Color(0xFF122E33),        // Xanh lơ đậm
    Color(0xFF2D2D2D),        // Xám than
  ];
}
