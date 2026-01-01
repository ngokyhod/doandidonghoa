import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_notification_provider.dart';
import '../admin_tab_provider.dart';
import 'package:intl/intl.dart';

class AdminNotificationBell extends ConsumerWidget {
  const AdminNotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Luôn lắng nghe stream để cập nhật số lượng
    final countAsync = ref.watch(adminNotificationCountProvider);
    final count = countAsync.value ?? 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.grey),
          onPressed: () => _showNotificationPanel(context, ref),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$count', 
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), 
                textAlign: TextAlign.center
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thông báo mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng', style: TextStyle(color: Colors.blue, fontSize: 12))),
                  ],
                ),
              ),
              Expanded(
                child: ref.watch(adminNoticeListProvider).when(
                  data: (notices) => notices.isEmpty 
                    ? const Center(child: Text('Không có thông báo nào mới', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: notices.length,
                        itemBuilder: (context, index) {
                          final n = notices[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: Icon(n.tabIndex == 4 || n.tabIndex == 5 ? Icons.chat : Icons.info_outline, color: Colors.green, size: 18),
                            ),
                            title: Text(n.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                            subtitle: Text(n.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: Text(DateFormat('HH:mm').format(n.time), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            onTap: () {
                              Navigator.pop(context);
                              // Nếu là tin nhắn, bạn có thể cần thêm logic set UID ở đây
                              ref.read(adminTabProvider.notifier).setTab(n.tabIndex);
                            },
                          );
                        },
                      ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Lỗi: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
