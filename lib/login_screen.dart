import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Mới thêm: Để lưu data

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

  // Client ID cho Web (Không quan trọng nếu chỉ chạy Android)
  static const String _webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  // --- 1. XỬ LÝ ĐĂNG NHẬP THƯỜNG ---
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
      // Đăng nhập thành công -> Router tự chuyển
    } on FirebaseAuthException catch (e) {
      String msg = "Đăng nhập thất bại";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        msg = "Tài khoản hoặc mật khẩu không đúng";
      } else if (e.code == 'wrong-password') {
        msg = "Sai mật khẩu";
      } else if (e.code == 'too-many-requests') {
        msg = "Thử lại sau ít phút";
      }
      _showMsg(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. XỬ LÝ GOOGLE LOGIN + LƯU FIRESTORE ---
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      if (!_isGoogleInitialized) {
        await googleSignIn.initialize(clientId: kIsWeb ? _webClientId : null);
        _isGoogleInitialized = true;
      }

      const List<String> scopes = [
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
      ];

      // Bước 1: Hiện bảng chọn tài khoản
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate(
        scopeHint: scopes,
      );

      // Bước 2: Lấy thông tin xác thực
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      // Bước 3: Lấy Token (Fix lỗi phiên bản mới)
      final authClient = googleUser.authorizationClient;
      var authz = await authClient.authorizationForScopes(scopes);
      authz ??= await authClient.authorizeScopes(scopes);

      final String? accessToken = authz?.accessToken;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) throw Exception("Không tìm thấy ID Token");

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Bước 4: Đăng nhập vào Firebase Auth
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // --- BƯỚC 5: LƯU USER VÀO FIRESTORE (QUAN TRỌNG) ---
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        // Kiểm tra xem user này đã có trong database chưa
        final docSnapshot = await userDocRef.get();

        if (!docSnapshot.exists) {
          // Nếu chưa có (Lần đầu đăng nhập) -> Lưu thông tin mới
          await userDocRef.set({
            'uid': user.uid,
            'fullName': user.displayName ?? "Người dùng Google",
            'email': user.email,
            'photoURL': user.photoURL,
            'phoneNumber': user.phoneNumber ?? "",
            'address': "", // Để trống để user cập nhật sau
            'role': 'farmer', // Mặc định là nông dân
            'createdAt': FieldValue.serverTimestamp(),
            'loginMethod': 'google',
          });
        }
      }
      // -----------------------------------------------------

    } catch (e) {
      if (!e.toString().contains('canceled') && !e.toString().contains('cancelled')) {
        _showMsg("Lỗi Google Login: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Xử lý Quên mật khẩu ---
  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Quên mật khẩu'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: "Nhập email của bạn"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                Navigator.of(dialogContext).pop();
                if (email.isEmpty) {
                  _showMsg("Vui lòng nhập email", isError: true);
                  return;
                }
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  _showMsg("Đã gửi link vào email!");
                } on FirebaseAuthException catch (e) {
                  _showMsg("Lỗi: ${e.message}", isError: true);
                }
              },
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.spa_rounded, size: 64, color: Colors.green),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chào mừng trở lại!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: const Text("Quên mật khẩu?", style: TextStyle(color: Colors.green)),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 30),
                const Center(child: Text("Hoặc", style: TextStyle(color: Colors.grey))),
                const SizedBox(height: 24),

                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                    height: 24, width: 24,
                    errorBuilder: (_,__,___) => const Icon(Icons.public, color: Colors.blue),
                  ),
                  label: const Text("Đăng nhập bằng Google", style: TextStyle(color: Colors.black87, fontSize: 16)),
                ),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Chưa có tài khoản? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Text("Đăng ký ngay", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}