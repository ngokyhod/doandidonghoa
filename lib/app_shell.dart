import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Lấy đường dẫn hiện tại để xác định tab đang chọn
    final String location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    // Logic ánh xạ đường dẫn -> Index của thanh menu
    if (location == '/') currentIndex = 0;
    else if (location.startsWith('/create_scrap_collection_request')) currentIndex = 1;
    else if (location.startsWith('/create_scrap_collection_request')) currentIndex = 2; // Giữa
    else if (location.startsWith('/products')) currentIndex = 3; // Bên phải nút giữa
    else if (location.startsWith('/profile')) currentIndex = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          // Logic chuyển trang khi bấm vào icon
          switch (index) {
            case 0: context.go('/'); break;
            case 1: context.go('/create_scrap_collection_request'); break;
            case 2: context.go('/create_scrap_collection_request'); break; // Quét/Thu gom
            case 3: context.go('/products'); break; // Chuyển sang trang Sản phẩm
            case 4: context.go('/profile'); break;
          }
        },
        destinations: const [
          // 0. Trang chủ
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Trang chủ'
          ),

          // 1. Chatbot (Thay thế hình chat cũ ở giữa bằng cái này ở bên trái)
          NavigationDestination(
            icon: Icon(Icons.recycling_outlined),
            selectedIcon: Icon(Icons.recycling),
            label: 'Thu gom',
          ),

          // 2. NÚT GIỮA: Quét phụ phẩm (Sửa lại icon thành QR Code hoặc Camera)
          NavigationDestination(
              icon: Icon(Icons.qr_code_scanner, size: 32, color: Colors.green),
              label: 'Quét QR'
          ),

          // 3. NÚT BÊN PHẢI: Sản phẩm (Sửa lại icon thành Giỏ hàng/Cửa hàng)
          NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Sản phẩm'
          ),

          // 4. Cá nhân
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Cá nhân'
          ),
        ],
      ),
    );
  }
}