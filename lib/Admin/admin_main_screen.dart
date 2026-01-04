import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'admin_tab_provider.dart';
import 'admin_product_screen.dart';
import 'admin_order_screen.dart';
import 'admin_users_screen.dart';
import 'admin_xnk_screen.dart';
import 'owner_dashboard_screen.dart';
import 'widgets/admin_notification_bell.dart';
import '../service/sync_service.dart';

class AdminMainScreen extends ConsumerWidget {
  const AdminMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(adminTabProvider);

    // Danh sách các màn hình con
    final List<Widget> pages = [
      const OwnerDashboardScreen(), // 0: Dashboard
      const AdminProductScreen(),   // 1: Sản phẩm
      const AdminOrderScreen(),     // 2: Đơn hàng
      const AdminXNKScreen(),       // 3: Kho & Thu gom
      const AdminUsersScreen(),     // 4: Khách hàng
      // const AdminChatScreen(),   // 5: Chat (Nếu bạn có)
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        // Bỏ tiêu đề "Quản lý hệ thống"
        title: const SizedBox.shrink(),
        actions: [
          // --- NÚT ĐỒNG BỘ DỜI LÊN ĐÂY ---
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: "Đồng bộ dữ liệu SQL",
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đang đồng bộ dữ liệu...")),
              );
              await SyncService.syncPendingOrders();
              // await SyncService.syncPendingScrapRequests();
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đồng bộ hoàn tất!")),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          // --- CHUÔNG THÔNG BÁO ---
          const AdminNotificationBell(),
          const SizedBox(width: 16),
        ],
      ),
      // Dùng IndexedStack để giữ trạng thái các tab
      body: IndexedStack(
        index: currentTab,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab > 4 ? 4 : currentTab, // Xử lý nếu tab > 4 (ví dụ chat)
        onTap: (index) => ref.read(adminTabProvider.notifier).setTab(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Thống kê'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Sản phẩm'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.warehouse), label: 'Kho/Thu gom'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Khách hàng'),
        ],
      ),
    );
  }
}