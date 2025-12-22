import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../service/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cartItems = CartService.cartItems;
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final double totalPrice = CartService.getTotalPrice();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Giỏ hàng của bạn"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Giỏ hàng đang trống", style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/products'), // Quay lại trang sản phẩm
              child: const Text("Đi mua sắm ngay"),
            )
          ],
        ),
      )
          : Column(
        children: [
          // Danh sách sản phẩm
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Image.network(
                      item.product.imageUrls.first,
                      width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => const Icon(Icons.image),
                    ),
                    title: Text(item.product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Đơn giá: ${formatCurrency.format(item.product.price)} / kg"),
                        Text("Khối lượng: ${item.weight} kg", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          CartService.removeFromCart(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Phần tổng tiền và nút bấm
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng cộng:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(formatCurrency.format(totalPrice), style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Nút Mua tiếp (Thoát ra trang sản phẩm)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          // Nếu dùng context.pop() sẽ quay lại trang Detail
                          // Nếu muốn về hẳn trang danh sách sản phẩm thì dùng context.go('/products')
                          context.go('/products');
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text("Mua tiếp"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nút Thanh toán (Giả lập)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng thanh toán đang phát triển")));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text("Thanh toán", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}