import 'package:doandidonghoa/model/product_model.dart';
import 'package:doandidonghoa/screen/cart_screen.dart';
import 'package:doandidonghoa/screen/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'app_shell.dart'; // Import file AppShell
import 'screen/home_screen.dart';
import 'screen/login_screen.dart';
import 'screen/register_screen.dart';
import 'screen/create_scrap_collection_request_screen.dart';
import 'screen/product_list_screen.dart'; // Import trang sản phẩm
import 'screen/chatbot_screen.dart'; // Nếu có
import 'screen/admin_chat_screen.dart'; // Nếu có
import 'screen/profile_screen.dart';

// --- Global Keys ---
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

// --- Cấu hình Router ---
final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  // Tự động chuyển hướng nếu chưa đăng nhập (Tuỳ chỉnh logic này theo ý bạn)
  redirect: (context, state) {
    // Cho phép xem trang chủ và sản phẩm mà không cần login
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

    // --- SHELL ROUTE (Chứa thanh điều hướng dưới đáy) ---
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        // 1. Trang chủ
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

        // 2. Thu gom (Hoặc Chatbot tùy bạn sắp xếp)
        GoRoute(path: '/create_scrap_collection_request', builder: (context, state) => const CreateScrapCollectionRequestScreen()),

        // 3. Quét phụ phẩm (Nút Giữa)
        GoRoute(path: '/create_scrap_collection_request', builder: (context, state) => const CreateScrapCollectionRequestScreen()),
        GoRoute(
          path: '/chatbot',
          builder: (context, state) => const ChatbotScreen(),
        ),
        // 4. Sản phẩm (Nút Bên Phải) -> Đã nối vào ProductListScreen
        GoRoute(
          path: '/products',
          builder: (context, state) {
            // Lấy tham số 'search' từ URL (nếu có)
            final searchQuery = state.uri.queryParameters['search'];

            // Truyền vào màn hình
            return ProductListScreen(initialSearchQuery: searchQuery);
          },
        ),

        // 5. Cá nhân
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    // Các trang con (Chi tiết sản phẩm) - Che lấp cả thanh menu
    GoRoute(
      path: '/product/:id',
      parentNavigatorKey: _rootNavigatorKey, // Giữ nguyên key của bạn
      builder: (context, state) {
        // 1. Lấy object Product được truyền kèm (từ danh sách sản phẩm)
        final product = state.extra as Product?;

        // 2. Kiểm tra an toàn:
        // Vì màn hình Detail mới bắt buộc phải có object 'product' để hiển thị giá/tên
        // Nếu người dùng reload trang web hoặc nhập link trực tiếp, 'product' sẽ bị null.
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Lỗi")),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Không tìm thấy thông tin sản phẩm."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => context.go('/products'),
                    child: const Text("Quay lại danh sách"),
                  )
                ],
              ),
            ),
          );
        }

        // 3. Truyền đúng tham số 'product' (Không dùng productId nữa)
        return ProductDetailScreen(product: product);
      },
    ),

  ],
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AgriMarket',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      routerConfig: _router,
    );
  }
}