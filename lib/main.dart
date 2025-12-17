import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import file cấu hình Firebase (Bắt buộc phải có file này trong lib/)
import 'firebase_options.dart';

// Import màn hình Thu Gom bạn đã code
import 'create_scrap_collection_request_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

// --- CẤU HÌNH ĐIỀU HƯỚNG (ROUTER) ---
final _router = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthPage = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (!loggedIn && !isAuthPage) return '/login';
    if (loggedIn && isAuthPage) return '/';
    return null;
  },
  routes: [
    // 1. Trang chủ
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

    // 2. Đăng nhập & Đăng ký
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

    // 3. Chức năng Thu Gom (Bán phụ phẩm)
    GoRoute(
        path: '/create_scrap_collection_request',
        builder: (context, state) => const CreateScrapCollectionRequestScreen()
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
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      routerConfig: _router,
    );
  }
}

// --- GIAO DIỆN CÁC MÀN HÌNH CƠ BẢN (Để không bị lỗi Import) ---

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AgriMarket"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Chào mừng bạn đến với AgriMarket", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text("TẠO YÊU CẦU THU GOM"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => context.push('/create_scrap_collection_request'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => FirebaseAuth.instance.signInAnonymously(),
              child: const Text("Đăng nhập ẩn danh (Để Test)"),
            ),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text("Chưa có tài khoản? Đăng ký ngay"),
            )
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: const Center(child: Text("Giao diện Đăng ký ở đây")),
    );
  }
}