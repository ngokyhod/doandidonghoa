import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'create_scrap_collection_request_screen.dart';

// QUAN TRỌNG: Import file chứa giao diện chính bạn vừa làm
import 'home_screen.dart';
// import 'product_detail_screen.dart'; // (Tạo file này sau để xem chi tiết sp)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

// --- CẤU HÌNH ROUTER ---
final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

  redirect: (BuildContext context, GoRouterState state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    // Chưa đăng nhập -> Đá về login
    if (!loggedIn && !isLoggingIn) return '/login';

    // Đã đăng nhập -> Đá về trang chủ
    if (loggedIn && isLoggingIn) return '/';

    return null;
  },
  routes: [
    // Trang chủ: Code sẽ lấy từ file home_screen.dart
    GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen()
    ),

    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
        path: '/create_scrap_collection_request',
        builder: (context, state) => const CreateScrapCollectionRequestScreen()
    ),

    // BỔ SUNG: Vì trong HomeScreen cũ bạn có code bấm vào sản phẩm
    // context.push('/product/${product.id}') nên cần định nghĩa route này để không bị lỗi
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        // Tạm thời hiển thị màn hình trắng text, sau này bạn tạo ProductDetailScreen sau
        final productId = state.pathParameters['id'];
        return Scaffold(
          appBar: AppBar(title: Text("Sản phẩm $productId")),
          body: const Center(child: Text("Chi tiết sản phẩm đang phát triển")),
        );
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

// Class tiện ích giúp GoRouter lắng nghe Firebase Auth
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

// --- ĐÃ XÓA CLASS HomeScreen Ở ĐÂY ĐỂ DÙNG TỪ FILE home_screen.dart ---