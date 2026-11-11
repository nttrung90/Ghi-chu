import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/backup_provider.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase (Bọc trong try-catch để app vẫn chạy offline mượt mà nếu chưa cấu hình key)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase chưa khởi tạo hoặc đang chạy chế độ Local-Only: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => BackupProvider()),
      ],
      child: const NoteNTTApp(),
    ),
  );
}

class NoteNTTApp extends StatelessWidget {
  const NoteNTTApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final notesProvider = context.read<NotesProvider>();

    // Tự động kết nối User ID của Firebase vào NotesProvider để đồng bộ
    if (authProvider.isAuthenticated) {
      notesProvider.updateUserId(authProvider.user?.uid);
    }

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const HomeScreen(),
    );
  }
}
