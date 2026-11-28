// File này được cấu hình tự động khi bạn chạy lệnh:
// flutterfire configure
// Cấu hình Android bên dưới lấy từ android/app/google-services.json
// (dự án Firebase note-ntt). Các nền tảng còn lại vẫn là giá trị mẫu.

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

  // Lưu ý: appId Android dưới đây được đăng ký cho package com.ntt.note_ntt,
  // trong khi applicationId hiện tại là com.ntt.notentt. Hãy tạo lại Android app
  // đúng package trong Firebase Console rồi chạy `flutterfire configure`
  // để nhận appId chính xác.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDjZDigAPzf7075FmQXRvROab98r6jhp4M',
    appId: '1:351311979378:android:60662fcf4a12baa84633eb',
    messagingSenderId: '351311979378',
    projectId: 'note-ntt',
    storageBucket: 'note-ntt.firebasestorage.app',
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
