import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/notes_provider.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final syncStatus = context.watch<NotesProvider>().syncStatus;

    Widget icon;
    String tooltip;
    Color color;

    switch (syncStatus) {
      case SyncStatus.syncing:
        icon = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        tooltip = 'Đang đồng bộ với Firebase...';
        color = Colors.blue;
        break;
      case SyncStatus.synced:
        icon = const Icon(Icons.cloud_done, size: 18, color: Colors.green);
        tooltip = 'Dữ liệu đã được đồng bộ an toàn trên đám mây';
        color = Colors.green;
        break;
      case SyncStatus.offline:
        icon = const Icon(Icons.cloud_off, size: 18, color: Colors.orange);
        tooltip = 'Đang ở chế độ ngoại tuyến (Sẽ đồng bộ khi có mạng)';
        color = Colors.orange;
        break;
      case SyncStatus.error:
        icon = const Icon(Icons.sync_problem, size: 18, color: Colors.red);
        tooltip = 'Lỗi đồng bộ';
        color = Colors.red;
        break;
      case SyncStatus.idle:
        icon = const Icon(Icons.cloud_queue, size: 18, color: Colors.grey);
        tooltip = 'Sẵn sàng đồng bộ';
        color = Colors.grey;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              syncStatus == SyncStatus.syncing
                  ? 'Đang đồng bộ'
                  : syncStatus == SyncStatus.synced
                      ? 'Đã đồng bộ'
                      : 'Ngoại tuyến',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
