import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'owner_dashboard_screen.dart';
import 'admin_product_screen.dart';
import 'admin_order_screen.dart';
import 'admin_xnk_screen.dart';
import 'admin_tab_provider.dart';
import 'admin_users_screen.dart';
import '../screen/admin_chat_screen.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  @override
  Widget build(BuildContext context) {
    // Đưa danh sách màn hình vào trong hàm build để đảm bảo không bị null trên Web
    final List<Widget> mainScreens = [
      const OwnerDashboardScreen(), // 0
      const AdminProductScreen(),   // 1
      const AdminOrderScreen(),     // 2
      const AdminXNKScreen(),       // 3
      const AdminUsersScreen(),     // 4
    ];

    final selectedIndex = ref.watch(adminTabProvider);

    // Xử lý logic hiển thị an toàn
    Widget currentBody;
    if (selectedIndex == 5) {
      currentBody = const AdminChatScreen();
    } else {
      // Đảm bảo index luôn nằm trong phạm vi của mainScreens (0-4)
      int safeIndex = (selectedIndex < 0 || selectedIndex >= mainScreens.length) ? 0 : selectedIndex;
      currentBody = IndexedStack(
        index: safeIndex,
        children: mainScreens,
      );
    }

    return Scaffold(
      body: currentBody,
      bottomNavigationBar: BottomNavigationBar(
        // Luôn highlight đúng icon cho dù đang ở trang Chat (5) hay trang Khách hàng (4)
        currentIndex: selectedIndex >= 4 ? 4 : (selectedIndex < 0 ? 0 : selectedIndex),
        onTap: (index) {
          ref.read(adminTabProvider.notifier).setTab(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Sản phẩm'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.warehouse_outlined), activeIcon: Icon(Icons.warehouse), label: 'Kho & Thu gom'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Khách hàng'),
        ],
      ),
    );
  }
}
