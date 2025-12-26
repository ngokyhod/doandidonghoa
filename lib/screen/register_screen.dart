import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../service/ApiService.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(); // Thêm ô nhập SĐT
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showMsg("Vui lòng nhập đủ thông tin", isError: true);
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showMsg("Mật khẩu không khớp", isError: true);
      return;
    }
    if (!RegExp(r'[A-ZÀ-Ỹ]').hasMatch(email)) {
      _showMsg("Họ tên phải có ít nhất 1 chữ viết hoa (VD: Nguyen Van A)", isError: true);
      return;
    }
    // (Tuỳ chọn) Chặn số và ký tự đặc biệt trong tên
    if (RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(name)) {
      _showMsg("Họ tên không được chứa số hoặc ký tự đặc biệt", isError: true);
      return;
    }
    setState(() => _isLoading = true);

    try {
      // BƯỚC 1: TẠO TÀI KHOẢN FIREBASE AUTH
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        final uid = user.uid;
        final name = _nameCtrl.text.trim();
        final email = _emailCtrl.text.trim();
        final phone = _phoneCtrl.text.trim();

        // BƯỚC 2: LƯU VÀO FIREBASE FIRESTORE (Như code bạn gửi)
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'fullName': name,
          'email': email,
          'phone': phone,
          'role': 'farmer',
          'createdAt': FieldValue.serverTimestamp(),
          'loginMethod': 'email',
        });
        print("✅ Lưu Firestore thành công!");

        // BƯỚC 3: GỌI API ĐỒNG BỘ SANG VISUAL (SQL SERVER)
        // Đây là bước quan trọng để 2 bên có cùng dữ liệu
        bool synced = await ApiService.syncUserToBackend(uid, email, name, phone);

        if (synced) {
          _showMsg("Đăng ký & Đồng bộ thành công!");
        } else {
          _showMsg("Đăng ký thành công (Lỗi đồng bộ Server)", isError: true);
        }

        // Chuyển trang sau khi xong
        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          context.pop(); // Về Login
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Lỗi: ${e.message}";
      if (e.code == 'email-already-in-use') msg = "Email này đã được đăng ký";
      _showMsg(msg, isError: true);
    } catch (e) {
      _showMsg("Lỗi không xác định: $e", isError: true);
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
      appBar: AppBar(title: const Text("Đăng ký tài khoản")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Các TextField nhập liệu
            _buildTextField(label: "Họ tên", icon: Icons.person, controller: _nameCtrl),
            const SizedBox(height: 16),
            _buildTextField(label: "Số điện thoại", icon: Icons.phone, controller: _phoneCtrl, inputType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(label: "Email", icon: Icons.email, controller: _emailCtrl, inputType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(label: "Mật khẩu", icon: Icons.lock, controller: _passCtrl, isPass: true),
            const SizedBox(height: 16),
            _buildTextField(label: "Nhập lại mật khẩu", icon: Icons.lock, controller: _confirmPassCtrl, isPass: true),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ĐĂNG KÝ NGAY"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required IconData icon, required TextEditingController controller, bool isPass = false, TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      keyboardType: inputType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}