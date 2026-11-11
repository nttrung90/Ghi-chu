import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  // Khởi tạo dữ liệu locale tiếng Việt cho DateFormat
  await initializeDateFormatting('vi', null);

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

class NoteNTTApp extends StatefulWidget {
  const NoteNTTApp({super.key});

  @override
  State<NoteNTTApp> createState() => _NoteNTTAppState();
}

class _NoteNTTAppState extends State<NoteNTTApp> {
  AuthProvider? _authProvider;
  NotesProvider? _notesProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notesProvider = context.read<NotesProvider>();

    final authProvider = context.read<AuthProvider>();
    if (!identical(_authProvider, authProvider)) {
      _authProvider?.removeListener(_syncUser);
      _authProvider = authProvider;
      _authProvider!.addListener(_syncUser);
      _syncUser();
    }
  }

  /// Đồng bộ User ID sang NotesProvider ngoài thời điểm build,
  /// tránh lỗi "setState() called during build".
  void _syncUser() {
    Future.microtask(() {
      if (!mounted) return;
      final auth = _authProvider;
      _notesProvider?.updateUserId(
        auth != null && auth.isAuthenticated ? auth.user?.uid : null,
      );
    });
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_syncUser);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

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
