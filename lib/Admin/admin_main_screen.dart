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
import '../screen/admin_chat_screen.dart'; // <--- 1. NHỚ IMPORT MÀN HÌNH CHAT

class AdminMainScreen extends ConsumerWidget {
  const AdminMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(adminTabProvider);

    // Danh sách các màn hình con
    final List<Widget> pages = [
      const OwnerDashboardScreen(), // Index 0
      const AdminProductScreen(),   // Index 1
      const AdminOrderScreen(),     // Index 2
      const AdminXNKScreen(),       // Index 3
      const AdminUsersScreen(),     // Index 4
      const AdminChatScreen(),      // Index 5 <--- 2. THÊM DÒNG NÀY ĐỂ KHẮC PHỤC LỖI
    ];

    // Xác định đang ở màn hình Chat hay không để ẩn hiện UI phù hợp
    bool isChatScreen = currentTab == 5;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        // Nếu đang ở màn hình Chat, đổi tiêu đề và hiện nút Back
        title: isChatScreen
            ? const Text("Hỗ trợ khách hàng", style: TextStyle(color: Colors.white, fontSize: 18))
            : const SizedBox.shrink(),
        leading: isChatScreen
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Quay lại màn hình Users (Tab 4)
            ref.read(adminTabProvider.notifier).setTab(4);
            // Hoặc xóa user đang chọn để reset chat
            // ref.read(selectedChatUserProvider.notifier).clear();
          },
        )
            : null,
        actions: [
          // Ẩn nút đồng bộ khi đang Chat cho đỡ rối
          if (!isChatScreen)
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
      ),

      // IndexedStack giữ trạng thái của các màn hình
      body: IndexedStack(
        index: currentTab,
        children: pages,
      ),

      // Ẩn BottomBar khi vào màn hình Chat để có không gian gõ phím
      bottomNavigationBar: isChatScreen
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
          BottomNavigationBarItem(icon: Icon(Icons.warehouse), label: 'Kho/XNK'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Khách hàng'),
        ],
      ),
    );
  }
}