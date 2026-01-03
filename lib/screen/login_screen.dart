import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true; // Để ẩn/hiện mật khẩu

  // Client ID for Web platform
  static const String _webClientId = '608328512668-dojpfabus8lsstmt203ogagv6c0epcrc.apps.googleusercontent.com';
  Future<void> _checkRoleAndRedirect(User user) async {
    try {
      // Lấy dữ liệu user từ Firestore (giả sử collection tên là 'users')
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        if (userDoc.exists) {
          // Lấy field 'role', nếu không có thì mặc định là 'user'
          String role = (userDoc.data() as Map<String, dynamic>)['role'] ?? 'user';

          if (role == 'admin') {
            // NẾU LÀ ADMIN
            context.go('/admin');
          } else {
            // NẾU LÀ USER
            context.go('/'); // Hoặc '/' tùy vào route mặc định của bạn
          }
        } else {
          // Trường hợp đăng nhập thành công nhưng chưa có data trong Firestore
          // Chuyển về trang chủ mặc định
          context.go('/home');
        }
      }
    } catch (e) {
      _showMsg("Lỗi kiểm tra quyền: $e", isError: true);
    }
  }
  // Xử lý đăng nhập Email/Pass
  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ thông tin", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (userCredential.user != null) {
        await _checkRoleAndRedirect(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Đăng nhập thất bại";
      if (e.code == 'user-not-found') msg = "Tài khoản không tồn tại";
      if (e.code == 'wrong-password') msg = "Sai mật khẩu";
      _showMsg(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Xử lý Google Login
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // Only pass clientId on web
        clientId: kIsWeb ? _webClientId : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled the login
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        // Lưu ý: Với Google Login lần đầu, bạn có thể cần tạo document user trong Firestore nếu chưa có
        // Ở đây tôi chỉ check role để điều hướng
        await _checkRoleAndRedirect(userCredential.user!);
      }
    } catch (e) {
      _showMsg("Lỗi Google Login: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Xử lý quên mật khẩu
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
                  _showMsg("Link đặt lại mật khẩu đã được gửi tới email của bạn.");
                } on FirebaseAuthException catch (e) {
                  String msg = "Có lỗi xảy ra";
                  if (e.code == 'user-not-found') {
                    msg = "Không tìm thấy tài khoản với email này.";
                  }
                  _showMsg(msg, isError: true);
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
                // 1. Logo & Header
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
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Text(
                  'Đăng nhập để tiếp tục mua sắm',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // 2. Form Nhập liệu
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.green, width: 2),
                    ),
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.green, width: 2),
                    ),
                  ),
                ),

                // Quên mật khẩu
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: const Text("Quên mật khẩu?", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Nút Đăng nhập
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 30),

                // 4. Hoặc đăng nhập bằng
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Hoặc", style: TextStyle(color: Colors.grey.shade600)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 24),

                // Nút Google
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                    height: 24, width: 24,
                    errorBuilder: (_,__,___) => const Icon(Icons.public, color: Colors.blue),
                  ),
                  label: const Text("Đăng nhập bằng Google", style: TextStyle(color: Colors.black87, fontSize: 16)),
                ),

                const SizedBox(height: 40),

                // 5. Chuyển sang Đăng ký
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
