import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_update_service.dart';

enum AppUpdateStatus {
  idle,
  checking,
  updateAvailable,
  upToDate,
  inProgress,
  updating,
  unsupported,
  error,
}

/// Quản lý trạng thái kiểm tra và cập nhật ứng dụng.
class AppUpdateProvider extends ChangeNotifier {
  static const String _dismissedVersionKey =
      'note_ntt_dismissed_update_version_code';

  AppUpdateStatus _status = AppUpdateStatus.idle;
  AppUpdateInfo? _updateInfo;
  String? _errorMessage;
  bool _autoCheckStarted = false;

  AppUpdateStatus get status => _status;
  AppUpdateInfo? get updateInfo => _updateInfo;
  String? get errorMessage => _errorMessage;

  bool get isBusy =>
      _status == AppUpdateStatus.checking ||
      _status == AppUpdateStatus.updating;

  String get statusLabel {
    switch (_status) {
      case AppUpdateStatus.idle:
        return 'Kiểm tra phiên bản mới trên Google Play';
      case AppUpdateStatus.checking:
        return 'Đang kiểm tra cập nhật...';
      case AppUpdateStatus.updateAvailable:
        return 'Đã có bản cập nhật mới. Nhấn để cập nhật.';
      case AppUpdateStatus.upToDate:
        return 'Bạn đang dùng phiên bản mới nhất.';
      case AppUpdateStatus.inProgress:
        return 'Bản cập nhật đang được tải về.';
      case AppUpdateStatus.updating:
        return 'Đang cập nhật qua Google Play...';
      case AppUpdateStatus.unsupported:
        return 'Chỉ hỗ trợ kiểm tra cập nhật trên Android qua Google Play.';
      case AppUpdateStatus.error:
        return _errorMessage ?? 'Không thể kiểm tra cập nhật.';
    }
  }

  /// Kiểm tra cập nhật theo yêu cầu của người dùng.
  Future<AppUpdateCheckResult> checkForUpdate() async {
    if (isBusy) {
      return const AppUpdateCheckResult(status: AppUpdateCheckStatus.busy);
    }

    _status = AppUpdateStatus.checking;
    _errorMessage = null;
    notifyListeners();

    final result = await AppUpdateService.checkForUpdate();
    _applyCheckResult(result);
    return result;
  }

  /// Tự kiểm tra một lần sau khi ứng dụng khởi động.
  ///
  /// Nếu người dùng đã bấm "Để sau" cho cùng một mã phiên bản,
  /// lần kiểm tra tự động sau sẽ không hiển thị lại hộp thoại.
  Future<AppUpdateCheckResult> autoCheckForUpdate() async {
    if (_autoCheckStarted) {
      return const AppUpdateCheckResult(status: AppUpdateCheckStatus.busy);
    }
    _autoCheckStarted = true;

    if (!AppUpdateService.isSupported) {
      _status = AppUpdateStatus.unsupported;
      notifyListeners();
      return const AppUpdateCheckResult(
        status: AppUpdateCheckStatus.unsupported,
        errorMessage:
            'Tính năng kiểm tra cập nhật hiện chỉ hỗ trợ trên Android qua Google Play.',
      );
    }

    final result = await checkForUpdate();
    if (result.status == AppUpdateCheckStatus.updateAvailable &&
        result.info != null) {
      final shouldNotify = await _shouldNotify(result.info!);
      return AppUpdateCheckResult(
        status: result.status,
        info: result.info,
        errorMessage: result.errorMessage,
        shouldNotify: shouldNotify,
      );
    }
    return result;
  }

  Future<bool> _shouldNotify(AppUpdateInfo info) async {
    final versionCode = info.availableVersionCode;
    if (versionCode == null) return true;

    final prefs = await SharedPreferences.getInstance();
    final dismissedVersion = prefs.getInt(_dismissedVersionKey);
    return dismissedVersion != versionCode;
  }

  /// Ghi nhớ phiên bản người dùng đã chọn cập nhật sau.
  Future<void> dismissUpdate(AppUpdateInfo info) async {
    final versionCode = info.availableVersionCode;
    if (versionCode == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedVersionKey, versionCode);
  }

  /// Bắt đầu cập nhật bằng Google Play In-App Updates API.
  Future<AppUpdateActionResult> startUpdate() async {
    final info = _updateInfo;
    if (info == null) {
      return const AppUpdateActionResult(
        AppUpdateActionStatus.failed,
        message: 'Không có thông tin bản cập nhật.',
      );
    }

    _status = AppUpdateStatus.updating;
    _errorMessage = null;
    notifyListeners();

    final result = await AppUpdateService.startUpdate(info);
    switch (result.status) {
      case AppUpdateActionStatus.success:
        _status = AppUpdateStatus.upToDate;
        break;
      case AppUpdateActionStatus.userDenied:
        _status = AppUpdateStatus.updateAvailable;
        break;
      case AppUpdateActionStatus.failed:
        _status = AppUpdateStatus.error;
        _errorMessage = result.message;
        break;
    }
    notifyListeners();
    return result;
  }

  void _applyCheckResult(AppUpdateCheckResult result) {
    switch (result.status) {
      case AppUpdateCheckStatus.updateAvailable:
        _updateInfo = result.info;
        _status = AppUpdateStatus.updateAvailable;
        _errorMessage = null;
        break;
      case AppUpdateCheckStatus.upToDate:
        _updateInfo = null;
        _status = AppUpdateStatus.upToDate;
        _errorMessage = null;
        break;
      case AppUpdateCheckStatus.inProgress:
        _updateInfo = result.info;
        _status = AppUpdateStatus.inProgress;
        _errorMessage = null;
        break;
      case AppUpdateCheckStatus.unsupported:
        _status = AppUpdateStatus.unsupported;
        _errorMessage = result.errorMessage;
        break;
      case AppUpdateCheckStatus.busy:
        break;
      case AppUpdateCheckStatus.error:
        _status = AppUpdateStatus.error;
        _errorMessage = result.errorMessage;
        break;
    }
    notifyListeners();
  }
}
