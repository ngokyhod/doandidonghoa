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
import '../screen/admin_chat_screen.dart'; // <--- 1. IMPORT MÀN HÌNH CHAT

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
      const AdminChatScreen(),      // 5: Chat (ĐÃ THÊM VÀO ĐÂY)
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        // Khi ở màn hình Chat (Tab 5), đổi tiêu đề AppBar
        title: currentTab == 5
            ? const Text("Hỗ trợ khách hàng", style: TextStyle(color: Colors.white, fontSize: 18))
            : const SizedBox.shrink(),
        actions: [
          // Nút đồng bộ (Chỉ hiện khi không phải màn hình Chat)
          if (currentTab != 5)
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              tooltip: "Đồng bộ dữ liệu SQL",
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đang đồng bộ dữ liệu...")),
                );
                await SyncService.syncPendingOrders();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đồng bộ hoàn tất!")),
                  );
                }
              },
            ),
          const SizedBox(width: 8),
          const AdminNotificationBell(),
          const SizedBox(width: 16),
        ],
        // Nếu ở màn hình chat, thêm nút Back để quay lại danh sách User
        leading: currentTab == 5
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => ref.read(adminTabProvider.notifier).setTab(4), // Quay về tab Khách hàng
        )
            : null,
      ),

      body: IndexedStack(
        index: currentTab,
        children: pages,
      ),

      // Ẩn thanh menu dưới đáy khi đang Chat để có không gian gõ phím
      bottomNavigationBar: currentTab == 5
          ? null
          : BottomNavigationBar(
        currentIndex: currentTab,
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