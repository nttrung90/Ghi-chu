// File này được cấu hình tự động khi bạn chạy lệnh:
// flutterfire configure
// Dưới đây là cấu hình mẫu hoặc dự phòng cho Note NTT.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Thay thế các giá trị dưới đây bằng thông tin cấu hình từ Firebase Console của bạn
  // Hoặc chạy lệnh `flutterfire configure` để tự động cập nhật
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyAndroidNoteNTT',
    appId: '1:1234567890:android:note_ntt',
    messagingSenderId: '1234567890',
    projectId: 'note-ntt-app',
    storageBucket: 'note-ntt-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyIOSNoteNTT',
    appId: '1:1234567890:ios:note_ntt',
    messagingSenderId: '1234567890',
    projectId: 'note-ntt-app',
    storageBucket: 'note-ntt-app.appspot.com',
    iosBundleId: 'com.ntt.notentt',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyWindowsNoteNTT',
    appId: '1:1234567890:web:note_ntt_win',
    messagingSenderId: '1234567890',
    projectId: 'note-ntt-app',
    storageBucket: 'note-ntt-app.appspot.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyWebNoteNTT',
    appId: '1:1234567890:web:note_ntt_web',
    messagingSenderId: '1234567890',
    projectId: 'note-ntt-app',
    storageBucket: 'note-ntt-app.appspot.com',
  );
}
