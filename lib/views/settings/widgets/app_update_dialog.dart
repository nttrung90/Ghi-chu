import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../../providers/app_update_provider.dart';
import '../../../services/app_update_service.dart';

/// Hiển thị hộp thoại thông báo có bản cập nhật mới.
///
/// Người dùng có thể chọn "Để sau" hoặc "Cập nhật ngay". Nếu chọn cập nhật,
/// quá trình tải và cài đặt sẽ do Google Play In-App Updates API xử lý.
Future<void> showAppUpdateDialog({
  required BuildContext context,
  required AppUpdateProvider provider,
  required AppUpdateInfo info,
  bool automatic = false,
}) async {
  final shouldUpdate = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);

      return AlertDialog(
        icon: Icon(
          Icons.system_update_alt_rounded,
          color: theme.colorScheme.primary,
        ),
        title: const Text('Đã có bản cập nhật mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              automatic
                  ? 'T-Note vừa có phiên bản mới trên Google Play. Bạn có muốn cập nhật ngay không?'
                  : 'Phiên bản mới của T-Note đã sẵn sàng trên Google Play. Cập nhật ngay để nhận các cải tiến và bản sửa lỗi mới nhất.',
            ),
            if (info.availableVersionCode != null) ...[
              const SizedBox(height: 12),
              Text(
                'Mã phiên bản: ${info.availableVersionCode}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Để sau'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Cập nhật ngay'),
          ),
        ],
      );
    },
  );

  if (shouldUpdate != true) {
    await provider.dismissUpdate(info);
    return;
  }

  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    const SnackBar(content: Text('Đang kết nối Google Play để cập nhật...')),
  );

  final result = await provider.startUpdate();
  if (!context.mounted) return;

  if (result.status == AppUpdateActionStatus.failed ||
      result.status == AppUpdateActionStatus.userDenied) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Không thể cập nhật ứng dụng lúc này.',
          ),
        ),
      );
  }
}
