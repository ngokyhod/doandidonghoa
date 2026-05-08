import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screen/chatbot_screen.dart'; // Import màn hình chat

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Hàm tính toán index dựa trên đường dẫn hiện tại
  int _calculateSelectedIndex(BuildContext context) {
    // Lấy đường dẫn hiện tại (ví dụ: '/products?search=abc' hoặc '/')
    final String location = GoRouterState.of(context).uri.path;

    // Logic so sánh:
    // 1. Trang chủ ('/') -> Index 0
    if (location == '/') return 0;

    // 2. Sản phẩm ('/products') -> Index 1
    if (location.startsWith('/products')) return 1;

    // 3. Thu gom ('/create_scrap_collection_request') -> Index 2 (Nút giữa)
    if (location.startsWith('/create_scrap_collection_request')) return 2;

    // 4. CSKH ('/admin_chat') -> Index 3
    if (location.startsWith('/admin_chat')) return 3;

    // 5. Cá nhân ('/profile') -> Index 4
    if (location.startsWith('/profile')) return 4;

    return 0; // Mặc định về trang chủ nếu không khớp
  }

  // Hàm xử lý khi bấm vào tab
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/'); // Về trang chủ
        break;
      case 1:
        context.go('/products'); // Sang danh sách sản phẩm
        break;
      case 2:
        context.go('/create_scrap_collection_request'); // Sang thu gom
        break;
      case 3:
        context.go('/admin_chat'); // Sang CSKH
        break;
      case 4:
        context.go('/profile'); // Sang profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body dùng Stack để vẽ nút Chat đè lên trên nội dung chính
      body: Stack(
        children: [
          // 1. Nội dung chính (Child từ ShellRoute)
          widget.child,

          // 2. Nút Chat bong bóng (Góc trên bên phải)

        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        // Lấy index hiện tại để highlight icon
        currentIndex: _calculateSelectedIndex(context),

        // Gọi hàm chuyển trang khi bấm
        onTap: (idx) => _onItemTapped(idx, context),

        type: BottomNavigationBarType.fixed, // Giữ cố định vị trí các nút

        // Màu sắc khi được chọn (Active)
        selectedItemColor: Colors.green,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),

        // Màu sắc khi không chọn (Inactive)
        unselectedItemColor: Colors.grey,

        showUnselectedLabels: true, // Luôn hiện chữ bên dưới

        items: const [
          // Index 0
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home), // Icon đậm hơn khi active
              label: 'Trang chủ'
          ),

          // Index 1
          BottomNavigationBarItem(
              icon: Icon(Icons.spa_outlined),
              activeIcon: Icon(Icons.spa),
              label: 'Sản phẩm'
          ),

          // Index 2 (Thu gom)
          BottomNavigationBarItem(
              icon: Icon(Icons.recycling_outlined),
              activeIcon: Icon(Icons.recycling),
              label: 'Thu gom'
          ),

          // Index 3
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'CSKH'
          ),

          // Index 4
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tôi'
          ),
        ],
      ),
    );
  }
}