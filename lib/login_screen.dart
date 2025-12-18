import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  // Biến kiểm tra khởi tạo Google
  static bool _isGoogleInitialized = false;

  // 1. XỬ LÝ ĐĂNG NHẬP THƯỜNG (EMAIL/PASS)
  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ thông tin", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      // Main.dart sẽ tự chuyển trang khi thấy có user
    } on FirebaseAuthException catch (e) {
      String msg = "Đăng nhập thất bại";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        msg = "Sai tài khoản hoặc mật khẩu";
      } else if (e.code == 'wrong-password') {
        msg = "Sai mật khẩu";
      }
      _showMsg(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. XỬ LÝ GOOGLE LOGIN (ĐÃ SỬA LỖI ACCESS TOKEN)
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      if (kIsWeb && !_isGoogleInitialized) {
        await googleSignIn.initialize();
        _isGoogleInitialized = true;
      }

      // Danh sách quyền (scopes) cần thiết
      const List<String> scopes = [
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
      ];

      // B1: Mở popup đăng nhập
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate(
        scopeHint: scopes,
      );

      if (googleUser == null) return; // User tắt popup

      // B2: Lấy thông tin xác thực cơ bản
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // --- SỬA LỖI Ở ĐÂY (Phiên bản v7) ---
      // AccessToken không còn nằm trong googleAuth nữa mà phải lấy qua AuthorizationClient
      final authClient = googleUser.authorizationClient;

      // Thử lấy token nếu đã có quyền
      var authz = await authClient.authorizationForScopes(scopes);
      // Nếu chưa có, yêu cầu quyền (hiện popup)
      authz ??= await authClient.authorizeScopes(scopes);

      final String? accessToken = authz?.accessToken;
      final String? idToken = googleAuth.idToken;
      // -------------------------------------

      if (idToken == null) {
        throw Exception("Không lấy được ID Token từ Google");
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // B3: Đăng nhập vào Firebase
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // B4: Lưu user vào Firestore (Nếu chưa có)
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'fullName': user.displayName ?? "Người dùng Google",
            'email': user.email,
            'photoURL': user.photoURL,
            'role': 'farmer',
            'createdAt': FieldValue.serverTimestamp(),
            'loginMethod': 'google',
          });
        }
      }

    } catch (e) {
      // Bỏ qua lỗi nếu người dùng tự hủy
      if (!e.toString().contains('canceled')) {
        _showMsg("Lỗi Google: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.spa, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passCtrl,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Đăng nhập", style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 20),
              const Text("- Hoặc -", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleLogin,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.login, color: Colors.red),
                label: const Text("Đăng nhập bằng Google", style: TextStyle(color: Colors.black)),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có tài khoản? "),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text("Đăng ký ngay", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}