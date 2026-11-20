import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformUtils {
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool isTabletOrDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 720;
  }

  /// Số cột lưới ghi chú dựa trên chiều rộng thực tế của vùng nội dung.
  static int getGridColumnCountForWidth(double width) {
    if (width >= 1500) return 5;
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 320) return 2;
    return 1;
  }

  static int getGridColumnCount(BuildContext context) {
    return getGridColumnCountForWidth(MediaQuery.of(context).size.width);
  }
}
