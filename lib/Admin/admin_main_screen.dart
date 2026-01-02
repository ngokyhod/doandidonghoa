import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Dùng để logout
import 'package:firebase_auth/firebase_auth.dart'; // Dùng để logout

// Các màn hình con
import 'owner_dashboard_screen.dart';
import 'admin_product_screen.dart';
import 'admin_order_screen.dart';
import 'admin_xnk_screen.dart';
import 'admin_tab_provider.dart';
import 'admin_users_screen.dart';
import '../screen/admin_chat_screen.dart';

// Service API để gọi đồng bộ
import 'admin_api_service.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  // Biến trạng thái để hiện vòng xoay loading khi đang đồng bộ
  bool _isSyncing = false;

  // --- HÀM XỬ LÝ ĐỒNG BỘ DỮ LIỆU ---
  Future<void> _handleSyncData() async {
    // 1. Hiện hộp thoại xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đồng bộ dữ liệu?"),
        content: const Text("Hành động này sẽ lấy toàn bộ sản phẩm từ SQL Server và cập nhật đè lên Firebase. Bạn có chắc chắn không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng bộ ngay")),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Bắt đầu loading
    setState(() => _isSyncing = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⏳ Đang xử lý đồng bộ phía Server... Vui lòng đợi.")),
      );
    }

    // 3. Gọi API thông qua Service
    bool success = await AdminApiService.syncAllProducts();

    // 4. Kết thúc loading và báo kết quả
    if (mounted) {
      setState(() => _isSyncing = false);

      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("✅ Thành công"),
            content: const Text("Dữ liệu sản phẩm trên Firebase đã được làm mới theo SQL Server."),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("❌ Đồng bộ thất bại. Kiểm tra lại kết nối Server."),
              backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  // --- HÀM ĐĂNG XUẤT ---
  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/login'); // Chuyển về màn hình đăng nhập
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách màn hình (Logic cũ của bạn)
    final List<Widget> mainScreens = [
      const OwnerDashboardScreen(), // 0
      const AdminProductScreen(),   // 1
      const AdminOrderScreen(),     // 2
      const AdminXNKScreen(),       // 3
      const AdminUsersScreen(),     // 4
    ];

    final selectedIndex = ref.watch(adminTabProvider);

    // Xử lý logic hiển thị body (Logic cũ của bạn)
    Widget currentBody;
    if (selectedIndex == 5) {
      currentBody = const AdminChatScreen();
    } else {
      int safeIndex = (selectedIndex < 0 || selectedIndex >= mainScreens.length) ? 0 : selectedIndex;
      currentBody = IndexedStack(
        index: safeIndex,
        children: mainScreens,
      );
    }

    return Scaffold(
      // --- THÊM APPBAR VÀO ĐÂY ---
      appBar: AppBar(
        title: const Text("Quản trị hệ thống"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Nút Đồng bộ dữ liệu
          _isSyncing
              ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          )
              : IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: "Đồng bộ SQL -> Firebase",
            onPressed: _handleSyncData,
          ),

          // Nút Đăng xuất
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Đăng xuất",
            onPressed: _handleLogout,
          ),
        ],
      ),
      // ---------------------------

      body: currentBody,

      bottomNavigationBar: BottomNavigationBar(
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