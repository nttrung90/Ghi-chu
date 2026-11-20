import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

/// Kết quả kiểm tra cập nhật.
enum AppUpdateCheckStatus {
  updateAvailable,
  upToDate,
  inProgress,
  unsupported,
  busy,
  error,
}

class AppUpdateCheckResult {
  final AppUpdateCheckStatus status;
  final AppUpdateInfo? info;
  final String? errorMessage;

  /// Chỉ dùng cho lần kiểm tra tự động: có nên hiển thị thông báo hay không.
  final bool shouldNotify;

  const AppUpdateCheckResult({
    required this.status,
    this.info,
    this.errorMessage,
    this.shouldNotify = false,
  });
}

/// Kết quả bắt đầu quá trình cập nhật.
enum AppUpdateActionStatus { success, userDenied, failed }

class AppUpdateActionResult {
  final AppUpdateActionStatus status;
  final String? message;

  const AppUpdateActionResult(this.status, {this.message});
}

/// Dịch vụ kiểm tra và cập nhật ứng dụng bằng Google Play In-App Updates API.
///
/// API này chỉ hoạt động khi ứng dụng được cài đặt từ Google Play
/// (kênh nội bộ, kênh thử nghiệm hoặc bản phát hành chính thức).
class AppUpdateService {
  AppUpdateService._();

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Kiểm tra xem Google Play có phiên bản mới hơn hay không.
  static Future<AppUpdateCheckResult> checkForUpdate() async {
    if (!isSupported) {
      return const AppUpdateCheckResult(
        status: AppUpdateCheckStatus.unsupported,
        errorMessage:
            'Tính năng kiểm tra cập nhật hiện chỉ hỗ trợ trên Android qua Google Play.',
      );
    }

    try {
      final info = await InAppUpdate.checkForUpdate();

      switch (info.updateAvailability) {
        case UpdateAvailability.updateAvailable:
          return AppUpdateCheckResult(
            status: AppUpdateCheckStatus.updateAvailable,
            info: info,
          );

        case UpdateAvailability.developerTriggeredUpdateInProgress:
          // Nếu bản cập nhật đã tải xong từ lần trước, hoàn tất cài đặt ngay.
          if (info.installStatus == InstallStatus.downloaded) {
            await InAppUpdate.completeFlexibleUpdate();
          }
          return AppUpdateCheckResult(
            status: AppUpdateCheckStatus.inProgress,
            info: info,
          );

        case UpdateAvailability.updateNotAvailable:
          return AppUpdateCheckResult(
            status: AppUpdateCheckStatus.upToDate,
            info: info,
          );

        case UpdateAvailability.unknown:
          return const AppUpdateCheckResult(
            status: AppUpdateCheckStatus.error,
            errorMessage:
                'Không thể xác định phiên bản mới trên Google Play. Vui lòng thử lại sau.',
          );
      }
    } on PlatformException catch (error) {
      return AppUpdateCheckResult(
        status: AppUpdateCheckStatus.error,
        errorMessage: _friendlyError(error),
      );
    } on MissingPluginException {
      return const AppUpdateCheckResult(
        status: AppUpdateCheckStatus.error,
        errorMessage:
            'Không thể kết nối Google Play trên thiết bị này. Vui lòng thử lại sau.',
      );
    } catch (_) {
      return const AppUpdateCheckResult(
        status: AppUpdateCheckStatus.error,
        errorMessage:
            'Đã xảy ra lỗi khi kiểm tra cập nhật. Vui lòng thử lại sau.',
      );
    }
  }

  /// Bắt đầu cập nhật qua Google Play.
  ///
  /// Ưu tiên cập nhật toàn màn hình (immediate). Nếu Google Play không cho phép,
  /// dùng cập nhật nền (flexible) rồi hoàn tất cài đặt khi tải xong.
  static Future<AppUpdateActionResult> startUpdate(AppUpdateInfo info) async {
    if (!isSupported) {
      return const AppUpdateActionResult(
        AppUpdateActionStatus.failed,
        message: 'Cập nhật trực tiếp chỉ hỗ trợ trên Android qua Google Play.',
      );
    }

    try {
      if (info.immediateUpdateAllowed) {
        final result = await InAppUpdate.performImmediateUpdate();
        return _mapUpdateResult(result);
      }

      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result != AppUpdateResult.success) {
          return _mapUpdateResult(result);
        }

        // Quá trình tải đã hoàn tất, tiến hành cài đặt bản cập nhật.
        await InAppUpdate.completeFlexibleUpdate();
        return const AppUpdateActionResult(AppUpdateActionStatus.success);
      }

      return const AppUpdateActionResult(
        AppUpdateActionStatus.failed,
        message:
            'Google Play chưa cho phép cập nhật ứng dụng lúc này. Vui lòng thử lại sau.',
      );
    } on PlatformException catch (error) {
      return AppUpdateActionResult(
        AppUpdateActionStatus.failed,
        message: _friendlyError(error),
      );
    } on MissingPluginException {
      return const AppUpdateActionResult(
        AppUpdateActionStatus.failed,
        message: 'Không thể kết nối Google Play trên thiết bị này.',
      );
    } catch (_) {
      return const AppUpdateActionResult(
        AppUpdateActionStatus.failed,
        message: 'Không thể hoàn tất cập nhật. Vui lòng thử lại sau.',
      );
    }
  }

  static AppUpdateActionResult _mapUpdateResult(AppUpdateResult result) {
    switch (result) {
      case AppUpdateResult.success:
        return const AppUpdateActionResult(AppUpdateActionStatus.success);
      case AppUpdateResult.userDeniedUpdate:
        return const AppUpdateActionResult(
          AppUpdateActionStatus.userDenied,
          message: 'Bạn đã hủy bản cập nhật.',
        );
      case AppUpdateResult.inAppUpdateFailed:
        return const AppUpdateActionResult(
          AppUpdateActionStatus.failed,
          message:
              'Google Play không thể hoàn tất cập nhật. Vui lòng thử lại sau.',
        );
    }
  }

  static String _friendlyError(PlatformException error) {
    final raw = '${error.code} ${error.message ?? ''}'.toUpperCase();

    if (raw.contains('API_NOT_AVAILABLE')) {
      return 'Không thể kiểm tra cập nhật vì ứng dụng chưa được cài đặt từ Google Play.';
    }

    if (raw.contains('APP_NOT_OWNED')) {
      return 'Ứng dụng không thuộc tài khoản Google Play đang đăng nhập trên thiết bị.';
    }

    if (raw.contains('PLAY_STORE_NOT_FOUND')) {
      return 'Không tìm thấy Google Play Store trên thiết bị.';
    }

    if (raw.contains('INSTALL_IN_PROGRESS')) {
      return 'Bản cập nhật đang được cài đặt. Vui lòng chờ trong giây lát.';
    }

    if (raw.contains('DOWNLOAD_NOT_PRESENT')) {
      return 'Chưa có bản cập nhật nào được tải về để cài đặt.';
    }

    if (raw.contains('INSTALL_NOT_ALLOWED')) {
      return 'Thiết bị không cho phép cài đặt bản cập nhật lúc này.';
    }

    if (raw.contains('INSTALL_UNAVAILABLE')) {
      return 'Bản cập nhật hiện không khả dụng trên Google Play.';
    }

    if (raw.contains('INVALID_REQUEST')) {
      return 'Yêu cầu cập nhật không hợp lệ. Vui lòng thử lại sau.';
    }

    if (raw.contains('INTERNAL_ERROR')) {
      return 'Google Play gặp lỗi khi xử lý cập nhật. Vui lòng thử lại sau.';
    }

    if (raw.contains('REQUIRE_FOREGROUND_ACTIVITY')) {
      return 'Không thể kiểm tra cập nhật lúc này. Vui lòng mở lại ứng dụng và thử lại.';
    }

    if (raw.contains('REQUIRE_CHECK_FOR_UPDATE')) {
      return 'Vui lòng kiểm tra cập nhật trước khi bắt đầu cài đặt.';
    }

    if (raw.contains('USER_DENIED_UPDATE')) {
      return 'Bạn đã hủy bản cập nhật.';
    }

    // Mã số của InstallErrorCode khi message không kèm tên lỗi.
    if (raw.contains('(-3)')) {
      return 'Không thể kiểm tra cập nhật vì ứng dụng chưa được cài đặt từ Google Play.';
    }

    if (raw.contains('(-10)')) {
      return 'Ứng dụng không thuộc tài khoản Google Play đang đăng nhập trên thiết bị.';
    }

    if (raw.contains('(-9)')) {
      return 'Không tìm thấy Google Play Store trên thiết bị.';
    }

    if (raw.contains('(-8)')) {
      return 'Bản cập nhật đang được cài đặt. Vui lòng chờ trong giây lát.';
    }

    if (raw.contains('(-7)')) {
      return 'Chưa có bản cập nhật nào được tải về để cài đặt.';
    }

    if (raw.contains('(-6)')) {
      return 'Thiết bị không cho phép cài đặt bản cập nhật lúc này.';
    }

    if (raw.contains('(-5)')) {
      return 'Bản cập nhật hiện không khả dụng trên Google Play.';
    }

    if (raw.contains('(-4)')) {
      return 'Yêu cầu cập nhật không hợp lệ. Vui lòng thử lại sau.';
    }

    if (raw.contains('(-100)')) {
      return 'Google Play gặp lỗi khi xử lý cập nhật. Vui lòng thử lại sau.';
    }

    if (raw.contains('(-2)')) {
      return 'Google Play gặp lỗi không xác định. Vui lòng thử lại sau.';
    }

    if (raw.contains('IN_APP_UPDATE_FAILED') || raw.contains('TASK_FAILURE')) {
      return 'Google Play không thể kiểm tra cập nhật. Vui lòng thử lại sau.';
    }

    return 'Không thể kiểm tra cập nhật qua Google Play. Vui lòng thử lại sau.';
  }
}
