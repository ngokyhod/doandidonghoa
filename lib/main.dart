import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'theme_notifier.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'create_scrap_collection_request_screen.dart';
import 'app_shell.dart';
import 'cart_screen.dart';
import 'chatbot_screen.dart';
import 'profile_screen.dart';
import 'product_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

  redirect: (BuildContext context, GoRouterState state) {
    final user = FirebaseAuth.instance.currentUser;
    final loggedIn = user != null;

    // Danh sách các trang KHÔNG cần đăng nhập vẫn xem được
    final publicRoutes = ['/', '/login', '/register'];
    final isPublicRoute = publicRoutes.contains(state.matchedLocation) ||
        state.matchedLocation.startsWith('/product/');

    // 1. Nếu chưa đăng nhập và cố vào trang bảo mật (không phải public) -> Đá về login
    if (!loggedIn && !isPublicRoute) return '/login';

    // 2. Nếu đã đăng nhập mà lại vào trang login/register -> Đá về trang chủ
    if (loggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
      return '/';
    }

    return null; // Cho phép đi tiếp
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

    // --- SHELL ROUTE (Thanh điều hướng dưới đáy) ---
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        // Trang chủ nằm trong Shell để hiện thanh menu dưới
        GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen()
        ),
        GoRoute(path: '/create_scrap_collection_request', builder: (context, state) => const CreateScrapCollectionRequestScreen()),
        GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListScreen(),
        ),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListScreen(),
        ),
      ],
    ),

    // Chi tiết sản phẩm (Full màn hình, che menu dưới)
    GoRoute(
      path: '/product/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final productId = state.pathParameters['id'];
        // TODO: Thay bằng ProductDetailScreen thật của bạn
        return Scaffold(
          appBar: AppBar(title: Text("Sản phẩm $productId")),
          body: const Center(child: Text("Chi tiết sản phẩm")),
        );
      },
    ),
  ],
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nếu bạn có dùng ThemeNotifier thì watch ở đây, tạm thời mình để mặc định
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AgriMarket',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      routerConfig: _router,
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}