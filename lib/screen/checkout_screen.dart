import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần thêm package intl vào pubspec.yaml để format tiền
import '../model/cart_item_model.dart';
import '../service/ApiService.dart'; // Giả sử bạn sẽ viết hàm gửi đơn hàng ở đây
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/CheckoutService.dart';
import '../service/cart_service.dart';
import 'order_complete_screen.dart';
class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho form nhập liệu (Giống các field trong ASP.NET Model)
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedPaymentMethod; // Lưu mã phương thức (PT001, PT005)
  bool _isSubmitting = false;

  // Danh sách phương thức thanh toán giống select option trong HTML
  final List<Map<String, String>> _paymentMethods = [
    {'code': 'PT001', 'name': 'Thanh toán khi nhận hàng (COD)'},
    {'code': 'PT005', 'name': 'Thanh toán VNPAY'},
  ];

  // Hàm định dạng tiền tệ (VD: 50,000 ₫)
  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount);
  }
  Future<void> _fillSavedAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['fullName'] ?? _nameController.text;
          _phoneController.text = data['phoneNumber'] ?? _phoneController.text;
          _addressController.text = data['address'] ?? _addressController.text; // Kéo thêm cái address về
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã điền thông tin mặc định"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chưa có thông tin. Vui lòng vào Hồ sơ để lưu."), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      print("Lỗi kéo thông tin: $e");
    }
  }
  @override
  void initState() {
    super.initState();
    // Tự động điền thông tin nếu user đã đăng nhập (Tùy chọn)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? "";
      _phoneController.text = user.phoneNumber ?? ""; // Firebase Auth có thể không có sdt
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }
      // 1. Chuẩn bị dữ liệu gửi lên Server (Khớp với Model DACS.Models.DonHang)
      bool success = await CheckoutService.createOrder(
        uid: user.uid,
        hoTen: _nameController.text,
        sdt: _phoneController.text,
        diaChi: _addressController.text,
        ghiChu: _noteController.text,
        phuongThucThanhToan: _selectedPaymentMethod ?? "PT001", // Mặc định COD
        tongTien: widget.totalAmount,
        cartItems: widget.cartItems,
      );





        if (mounted) {
          if (success) {
            // 1. Xóa giỏ hàng local
            CartService.clearCart();

            // 2. Thông báo thành công
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Đặt hàng thành công!"), backgroundColor: Colors.green),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderCompleteScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ Đã lưu App nhưng lỗi đồng bộ Server."), backgroundColor: Colors.orange),
            );
          }
        }


    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xác nhận đơn hàng"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PHẦN 1: DANH SÁCH SẢN PHẨM (Tương ứng cột trái HTML) ---
              const Text("Chi tiết đơn hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ...widget.cartItems.map((item) => ListTile(
                      leading: Image.network(
                        item.imageUrl,
                        width: 50, height: 50, fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported),
                      ),
                      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text("${item.quantity} x ${formatCurrency(item.price)}"),
                      trailing: Text(
                        formatCurrency(item.price * item.quantity),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Tổng cộng:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            formatCurrency(widget.totalAmount),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- PHẦN 2: THÔNG TIN GIAO HÀNG (Tương ứng cột phải HTML) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Thông tin giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),

                  // 🔴 THÊM NÚT ĐIỀN TỰ ĐỘNG Ở ĐÂY
                  TextButton.icon(
                    onPressed: _fillSavedAddress,
                    icon: const Icon(Icons.flash_on, color: Colors.orange, size: 18),
                    label: const Text("Dùng sổ địa chỉ", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 10),

              // Họ tên
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Họ và tên người nhận", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (val) => (val == null || val.isEmpty) ? "Vui lòng nhập họ tên" : null,
              ),
              const SizedBox(height: 12),

              // Số điện thoại
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                validator: (val) => (val == null || val.length < 10) ? "SĐT không hợp lệ" : null,
              ),
              const SizedBox(height: 12),

              // Địa chỉ
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Địa chỉ nhận hàng", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                validator: (val) => (val == null || val.isEmpty) ? "Vui lòng nhập địa chỉ" : null,
              ),
              const SizedBox(height: 12),

              // Ghi chú
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Ghi chú", border: OutlineInputBorder(), prefixIcon: Icon(Icons.note)),
              ),
              const SizedBox(height: 12),

              // Phương thức thanh toán
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(labelText: "Phương thức thanh toán", border: OutlineInputBorder(), prefixIcon: Icon(Icons.payment)),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method['code'],
                    child: Text(method['name']!),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPaymentMethod = val),
                validator: (val) => val == null ? "Chọn phương thức thanh toán" : null,
              ),

              const SizedBox(height: 30),

              // Nút Đặt hàng
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ĐẶT HÀNG", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}