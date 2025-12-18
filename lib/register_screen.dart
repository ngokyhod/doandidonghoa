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

  Future<void> _handleRegister() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showMsg("Vui lòng nhập đủ thông tin", isError: true);
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showMsg("Mật khẩu không khớp", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Tạo user bên Authentication
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      // 2. Lưu thông tin phụ vào Firestore (Database)
      if (userCredential.user != null) {
        // Dòng này trả lời câu hỏi của bạn: Ta dùng user.uid làm ID cho document luôn
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'fullName': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'role': 'farmer', // Mặc định là nông dân
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': '',
          'address': '',
        });

        // Cập nhật tên hiển thị cho User Auth
        await userCredential.user!.updateDisplayName(_nameCtrl.text.trim());
      }

      _showMsg("Đăng ký thành công!");
      // Không cần context.go('/') vì main.dart sẽ tự chuyển khi thấy user đã login
    } on FirebaseAuthException catch (e) {
      String msg = "Lỗi đăng ký: ${e.code}";
      if (e.code == 'email-already-in-use') msg = "Email này đã có người dùng";
      if (e.code == 'weak-password') msg = "Mật khẩu quá yếu";
      _showMsg(msg, isError: true);
    } catch (e) {
      _showMsg("Lỗi: $e", isError: true);
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
      appBar: AppBar(title: const Text("Đăng ký")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Họ tên")),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 12),
            TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Mật khẩu")),
            const SizedBox(height: 12),
            TextField(controller: _confirmPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Nhập lại mật khẩu")),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading ? const CircularProgressIndicator() : const Text("ĐĂNG KÝ"),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text("Đã có tài khoản? Đăng nhập"),
            )
          ],
        ),
      ),
    );
  }
}