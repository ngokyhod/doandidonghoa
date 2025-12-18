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
// import 'profile_screen.dart'; // Bỏ comment nếu bạn đã tạo file này

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

// --- CẤU HÌNH ROUTER (ĐÃ SỬA LỖI) ---
final _router = GoRouter(
  initialLocation: '/',
  // QUAN TRỌNG: Dòng này giúp app tự chuyển trang khi Login/Logout
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

  redirect: (BuildContext context, GoRouterState state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    // Chưa đăng nhập mà không ở trang login/register -> Đá về login
    if (!loggedIn && !isLoggingIn) return '/login';

    // Đã đăng nhập mà vẫn ở trang login/register -> Đá về trang chủ
    if (loggedIn && isLoggingIn) return '/';

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
        path: '/create_scrap_collection_request',
        builder: (context, state) => const CreateScrapCollectionRequestScreen()
    ),
    // GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
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

// Màn hình trang chủ tạm thời
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang chủ"),
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
            Text("Xin chào: ${user?.email ?? 'Người dùng'}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/create_scrap_collection_request'),
              child: const Text("Tạo yêu cầu thu gom"),
            )
          ],
        ),
      ),
    );
  }
}