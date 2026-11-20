import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/backup_provider.dart';
import '../providers/notes_provider.dart';

/// Điều phối tự động sao lưu Google Drive:
/// - Debounce 30 giây sau thay đổi ghi chú cuối cùng.
/// - Sao lưu ngay khi ứng dụng chuyển xuống nền nếu còn dữ liệu chưa lưu.
/// - Kiểm tra lại khi ứng dụng khởi động hoặc quay lại foreground.
class AutoBackupCoordinator extends StatefulWidget {
  final Widget child;

  const AutoBackupCoordinator({super.key, required this.child});

  @override
  State<AutoBackupCoordinator> createState() => _AutoBackupCoordinatorState();
}

class _AutoBackupCoordinatorState extends State<AutoBackupCoordinator>
    with WidgetsBindingObserver {
  static const Duration _debounceDuration = Duration(seconds: 30);
  static const Duration _authReadyDelay = Duration(seconds: 2);

  NotesProvider? _notesProvider;
  AuthProvider? _authProvider;
  BackupProvider? _backupProvider;

  Timer? _debounceTimer;
  bool _isRunning = false;
  AutoBackupStatus? _lastBackupStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final notesProvider = context.read<NotesProvider>();
    if (!identical(_notesProvider, notesProvider)) {
      _notesProvider?.removeListener(_onNotesChanged);
      _notesProvider = notesProvider;
      _notesProvider!.addListener(_onNotesChanged);
    }

    final authProvider = context.read<AuthProvider>();
    if (!identical(_authProvider, authProvider)) {
      _authProvider?.removeListener(_onAuthChanged);
      _authProvider = authProvider;
      _authProvider!.addListener(_onAuthChanged);
    }

    final backupProvider = context.read<BackupProvider>();
    if (!identical(_backupProvider, backupProvider)) {
      _backupProvider?.removeListener(_onBackupSettingsChanged);
      _backupProvider = backupProvider;
      _backupProvider!.addListener(_onBackupSettingsChanged);
    }

    _evaluatePendingBackup();
  }

  void _onNotesChanged() {
    _evaluatePendingBackup();
  }

  void _onAuthChanged() {
    // Phiên Google có thể được khôi phục sau khi ghi chú đã tải xong.
    _evaluatePendingBackup(delay: _authReadyDelay);
  }

  void _onBackupSettingsChanged() {
    final backup = _backupProvider;
    if (backup == null) return;

    final previousStatus = _lastBackupStatus;
    final currentStatus = backup.autoBackupStatus;
    _lastBackupStatus = currentStatus;

    // Khi một lần auto backup vừa thất bại, không lên lịch thử lại ngay sau
    // 30 giây (tránh vòng lặp gọi mạng liên tục). Dữ liệu vẫn được giữ ở
    // trạng thái "dirty" và sẽ được thử lại khi có thay đổi mới, khi app
    // quay lại foreground, khi app xuống nền hoặc khi người dùng bấm "Thử lại".
    if (currentStatus == AutoBackupStatus.failed &&
        previousStatus == AutoBackupStatus.running) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      return;
    }

    _evaluatePendingBackup();
  }

  void _evaluatePendingBackup({
    Duration delay = _debounceDuration,
    bool immediate = false,
  }) {
    if (!mounted) return;

    final backup = _backupProvider;
    final notes = _notesProvider;
    if (backup == null || notes == null) return;

    final isPending = backup.hasPendingAutoBackup(
      account: _authProvider?.googleUser,
      notes: notes.allNotes,
    );

    if (!isPending) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      return;
    }

    _debounceTimer?.cancel();

    if (immediate) {
      _debounceTimer = null;
      unawaited(_runAutoBackup());
      return;
    }

    _debounceTimer = Timer(delay, () {
      _debounceTimer = null;
      unawaited(_runAutoBackup());
    });
  }

  Future<void> _runAutoBackup() async {
    if (_isRunning || !mounted) return;

    final backup = _backupProvider;
    final notes = _notesProvider;
    final account = _authProvider?.googleUser;
    if (backup == null || notes == null || account == null) return;

    if (!backup.hasPendingAutoBackup(
      account: account,
      notes: notes.allNotes,
    )) {
      return;
    }

    _isRunning = true;
    try {
      await backup.runAutoBackup(
        account: account,
        notes: notes.allNotes,
      );
    } finally {
      _isRunning = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Không chờ hết debounce khi ứng dụng sắp bị đưa xuống nền.
      _debounceTimer?.cancel();
      _debounceTimer = null;
      unawaited(_runAutoBackup());
    } else if (state == AppLifecycleState.resumed) {
      _evaluatePendingBackup(immediate: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _notesProvider?.removeListener(_onNotesChanged);
    _authProvider?.removeListener(_onAuthChanged);
    _backupProvider?.removeListener(_onBackupSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
