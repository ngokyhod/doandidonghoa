
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../model/cart_item_model.dart';
import '../service/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Giỏ hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: _cartService.getCartItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final cartItems = snapshot.data ?? [];
          
          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Giỏ hàng trống', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Tiếp tục mua sắm', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          double subtotal = cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _buildCartItem(item);
                  },
                ),
              ),
              _buildOrderSummary(subtotal),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl.startsWith('http')
                ? Image.network(item.imageUrl, width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                : Image.asset(item.imageUrl, width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder()),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 22),
                      onPressed: () => _cartService.removeItemFromCart(item.productId),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(_currencyFormat.format(item.price), style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildQtyBtn(Icons.remove, () {
                      if (item.quantity > 0.1) {
                        _cartService.updateItemQuantity(item.productId, item.quantity - 0.1);
                      }
                    }),
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      alignment: Alignment.center,
                      child: Text(item.quantity.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    _buildQtyBtn(Icons.add, () => _cartService.updateItemQuantity(item.productId, item.quantity + 0.1), isAdd: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isAdd ? const Color(0xFFE8F5E9) : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: isAdd ? const Color(0xFF2E7D32) : Colors.grey[600]),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(color: Colors.grey[100], width: 90, height: 90, child: const Icon(Icons.image_outlined, color: Colors.grey));

  Widget _buildOrderSummary(double subtotal) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tóm tắt đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildSummaryRow('Tạm tính', _currencyFormat.format(subtotal)),
          const SizedBox(height: 12),
          _buildSummaryRow('Phí vận chuyển', 'Sẽ được tính ở bước sau', isGrey: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_currencyFormat.format(subtotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGrey = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isGrey ? Colors.grey : Colors.black87, fontSize: 15)),
        Text(value, style: TextStyle(color: isGrey ? Colors.grey : Colors.black87, fontWeight: isGrey ? FontWeight.normal : FontWeight.w600, fontSize: 15)),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      color: Colors.white,
      child: ElevatedButton(
        onPressed: () => context.push('/checkout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('Tiến hành thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
