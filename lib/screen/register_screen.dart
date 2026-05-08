import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Thêm thư viện két sắt
import '../service/ApiService.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;

  // Khởi tạo két sắt bảo mật
  final _storage = const FlutterSecureStorage();

  Future<void> _handleRegister() async {
    // --- 1. LẤY GIÁ TRỊ TỪ CONTROLLER ---
    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    // --- 2. VALIDATE DỮ LIỆU ---
    if (name.isEmpty || email.isEmpty || pass.isEmpty || phone.isEmpty) {
      _showMsg("Vui lòng nhập đủ thông tin", isError: true);
      return;
    }
    if (pass != confirmPass) {
      _showMsg("Mật khẩu không khớp", isError: true);
      return;
    }
    if (!RegExp(r'[A-ZÀ-Ỹ]').hasMatch(name)) {
      _showMsg("Họ tên phải có ít nhất 1 chữ viết hoa", isError: true);
      return;
    }
    if (RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(name)) {
      _showMsg("Họ tên không được chứa số hoặc ký tự đặc biệt", isError: true);
      return;
    }

    // --- 3. TIẾN HÀNH ĐĂNG KÝ ---
    setState(() => _isLoading = true);

    try {
      // BƯỚC 1: TẠO TÀI KHOẢN FIREBASE AUTH
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = userCredential.user;
      if (user != null) {
        final uid = user.uid;

        // BƯỚC 2: LƯU FIREBASE FIRESTORE (OFFLINE FIRST)
        // Mặc định isSync = false và có timestamp
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'fullName': name,
          'email': email,
          'phone': phone,
          'role': 'KhachHang',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'loginMethod': 'email',
          'isSync': false, // Mặc định chưa đồng bộ
        });
        print("✅ Lưu Firestore thành công!");

        // BƯỚC 3: CẤT MẬT KHẨU VÀO KÉT SẮT (Dự phòng Web sập)
        // Lưu theo key có chứa UID để không bị nhầm lẫn giữa các tài khoản
        await _storage.write(key: 'unsynced_pass_$uid', value: pass);

        // BƯỚC 4: THỬ ĐỒNG BỘ LÊN WEB (ONLINE SYNC)
        try {
          bool synced = await ApiService.syncUserToBackend(uid, email, name, phone, pass);

          if (synced) {
            // 4.1: Nếu Web nhận thành công -> Cập nhật Firebase
            await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'isSync': true,
              'syncedAt': FieldValue.serverTimestamp(), // Timestamp đồng bộ thành công
            });

            // 4.2: XÓA MẬT KHẨU KHỎI KÉT SẮT NGAY LẬP TỨC
            await _storage.delete(key: 'unsynced_pass_$uid');

            _showMsg("Đăng ký & Đồng bộ Web thành công!");
          } else {
            // Lỗi logic từ Web (VD: Bị trùng email bên bảng SQL)
            _showMsg("Đăng ký App thành công nhưng Web từ chối.", isError: true);
          }
        } catch (e) {
          // BƯỚC 5: NẾU WEB SẬP HOẶC MẤT MẠNG RƠI VÀO ĐÂY
          // Mật khẩu đã an toàn trong két, isSync vẫn đang là false.
          _showMsg("Đăng ký thành công! Đang chờ đồng bộ lên Server...", isError: false);
        }

        // Chuyển trang sau 1 giây
        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) context.pop(); // Về trang trước
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Lỗi: ${e.message}";
      if (e.code == 'email-already-in-use') msg = "Email này đã được đăng ký";
      if (e.code == 'weak-password') msg = "Mật khẩu quá yếu (cần > 6 ký tự)";
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
    // ... Giữ nguyên Giao diện (Scaffold, AppBar, TextField...) của bạn ...
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký tài khoản")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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