import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../model/product_model.dart';
import '../service/cart_service.dart';
import 'package:flutter/services.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _weightController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _addToCart() {
    // 1. Kiểm tra đăng nhập
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để mua hàng!"), backgroundColor: Colors.red),
      );
      context.push('/login');
      return;
    }

    // 2. Kiểm tra khối lượng hợp lệ
    final weightString = _weightController.text.replaceAll(',', '.');
    final double? weight = double.tryParse(weightString);

    if (weight == null || weight <= 0) {
      setState(() => _errorText = "Vui lòng nhập khối lượng hợp lệ (> 0)");
      return;
    }

    // 3. Kiểm tra giới hạn 1000kg (Tùy chọn, có thể xóa nếu muốn mua vô hạn)
    if (weight > 1000) {
      setState(() => _errorText = "Khối lượng quá lớn (Tối đa 1000kg)");
      return;
    }

    // --- ĐÃ XÓA PHẦN KIỂM TRA TỒN KHO Ở ĐÂY ---

    // 5. Thêm vào giỏ hàng và chuyển trang
    CartService.addToCart(widget.product, weight);

    // Reset lỗi
    setState(() => _errorText = null);

    // Hiển thị thông báo và chuyển sang Cart
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã thêm ${weight}kg ${widget.product.title} vào giỏ!"), backgroundColor: Colors.green),
    );

    context.push('/cart');
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.product.imageUrls.isNotEmpty ? widget.product.imageUrls.first : '',
                height: 250, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 250, color: Colors.grey[200], child: const Icon(Icons.image, size: 50)),
              ),
            ),
            const SizedBox(height: 16),

            // Giá
            Text(formatCurrency.format(widget.product.price) + " / kg",
                style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            // Tên sản phẩm
            Text(widget.product.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            // Hiển thị tồn kho (Vẫn để lại để khách xem, nhưng không chặn)
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  "Tồn kho: ${widget.product.stockQuantity} ${widget.product.unit}",
                  style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(widget.product.description, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),

            // --- PHẦN NHẬP KHỐI LƯỢNG ---
            const Text("Nhập khối lượng muốn mua (kg):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              decoration: InputDecoration(
                hintText: "Ví dụ: 10.5",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: "kg",
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 24),

            // Nút Thêm vào giỏ (LUÔN BẬT)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _addToCart, // Luôn cho phép nhấn
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text(
                  "Thêm vào giỏ hàng",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Luôn hiện màu xanh
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}