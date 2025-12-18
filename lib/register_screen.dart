import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;

  // Thay thế toàn bộ hàm _handleRegister trong lib/register_screen.dart

  Future<void> _handleRegister() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ thông tin", isError: true);
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showMsg("Mật khẩu không khớp", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Tạo tài khoản Auth
      print("Bắt đầu tạo tài khoản Auth...");
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      print("Tạo Auth thành công: ${userCredential.user?.uid}");

      // 2. Lưu vào Firestore
      if (userCredential.user != null) {
        print("Bắt đầu lưu vào Firestore...");
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'fullName': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'role': 'farmer',
          'createdAt': FieldValue.serverTimestamp(),
          'loginMethod': 'email', // Thêm trường này để dễ quản lý
        });
        print("Lưu Firestore thành công!");
      }

      _showMsg("Đăng ký thành công!");
      // Không cần context.pop() nếu main.dart đã có logic tự chuyển trang

    } on FirebaseAuthException catch (e) {
      String msg = "Lỗi Auth: ${e.message}";
      if (e.code == 'email-already-in-use') msg = "Email này đã có người dùng";
      if (e.code == 'weak-password') msg = "Mật khẩu quá yếu";
      if (e.code == 'operation-not-allowed') msg = "Chưa bật Email/Password trong Console";

      _showMsg(msg, isError: true);
      print("Lỗi Firebase Auth: ${e.code} - ${e.message}");
    } on FirebaseException catch (e) {
      // Bắt lỗi riêng của Firestore (thường là permission-denied)
      String msg = "Lỗi Lưu Data: ${e.message}";
      if (e.code == 'permission-denied') msg = "Lỗi quyền truy cập Firestore (Check Rules)";

      _showMsg(msg, isError: true);
      print("Lỗi Firestore: ${e.code} - ${e.message}");
    } catch (e) {
      _showMsg("Lỗi không xác định: $e", isError: true);
      print("Lỗi khác: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tạo tài khoản mới',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Điền thông tin bên dưới để tham gia AgriMarket',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Form nhập liệu
              _buildTextField(label: "Họ và tên", icon: Icons.person_outline, controller: _nameCtrl),
              const SizedBox(height: 16),
              _buildTextField(label: "Email", icon: Icons.email_outlined, controller: _emailCtrl, inputType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(label: "Mật khẩu", icon: Icons.lock_outline, controller: _passCtrl, isPass: true),
              const SizedBox(height: 16),
              _buildTextField(label: "Nhập lại mật khẩu", icon: Icons.lock_outline, controller: _confirmPassCtrl, isPass: true),

              const SizedBox(height: 32),

              // Nút Đăng ký
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ĐĂNG KÝ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Đã có tài khoản? ", style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () => context.pop(), // Quay lại trang Login
                    child: const Text("Đăng nhập", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con để code gọn hơn
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPass = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
    );
  }
}