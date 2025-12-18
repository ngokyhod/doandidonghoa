import 'dart:async'; // Cần import để dùng StreamSubscription

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'profile_screen.dart';
// Import file cấu hình Firebase
import 'firebase_options.dart';

// --- IMPORT CÁC MÀN HÌNH CỦA BẠN ---
import 'create_scrap_collection_request_screen.dart';
import 'login_screen.dart';   // Import màn hình đăng nhập thật
import 'register_screen.dart'; // Import màn hình đăng ký thật

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
  // QUAN TRỌNG: Lắng nghe thay đổi trạng thái Auth để tự động redirect
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

  redirect: (BuildContext context, GoRouterState state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthPage = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    // Nếu chưa đăng nhập và không ở trang login/register -> Đá về login
    if (!loggedIn && !isAuthPage) return '/login';

    // Nếu đã đăng nhập mà vẫn ở trang login/register -> Đá về trang chủ
    if (loggedIn && isAuthPage) return '/';

    return null; // Không làm gì cả (cho phép đi tiếp)
  },
  routes: [
    // 1. Trang chủ
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),

    // 2. Đăng nhập & Đăng ký
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    // 3. Chức năng Thu Gom (Bán phụ phẩm)
    GoRoute(
      path: '/create_scrap_collection_request',
      builder: (context, state) => const CreateScrapCollectionRequestScreen(),
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

// --- CLASS HỖ TRỢ LẮNG NGHE AUTH (Để Router tự refresh) ---
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// --- GIAO DIỆN TRANG CHỦ (HOME) ---
// (LoginScreen và RegisterScreen đã bị xóa ở đây để dùng file import)

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy user hiện tại để hiển thị tên (nếu có)
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AgriMarket"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Đăng xuất -> Router sẽ tự phát hiện và đưa về Login
              FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                "Xin chào, ${user?.email ?? 'Người dùng'}!",
                style: const TextStyle(fontSize: 18)
            ),
            const SizedBox(height: 10),
            const Text("Chào mừng bạn đến với AgriMarket", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text("TẠO YÊU CẦU THU GOM"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => context.push('/create_scrap_collection_request'),
            ),
          ],
        ),
      ),
    );
  }
}