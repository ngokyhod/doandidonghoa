import '../model/product_model.dart';

class CartItem {
  final Product product;
  final double weight; // Khối lượng (kg)

  CartItem({required this.product, required this.weight});
}

class CartService {
  // Dùng static list để lưu tạm trong bộ nhớ (khi tắt app sẽ mất).
  // Nếu muốn lưu lâu dài cần dùng SQLite hoặc Firestore.
  static final List<CartItem> _cartItems = [];

  static List<CartItem> get cartItems => _cartItems;

  static void addToCart(Product product, double weight) {
    // Kiểm tra xem sản phẩm đã có trong giỏ chưa, nếu có thì cộng thêm khối lượng
    final index = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _cartItems[index] = CartItem(
          product: product,
          weight: _cartItems[index].weight + weight
      );
    } else {
      _cartItems.add(CartItem(product: product, weight: weight));
    }
  }

  static void removeFromCart(int index) {
    _cartItems.removeAt(index);
  }

  static double getTotalPrice() {
    return _cartItems.fold(0, (sum, item) => sum + (item.product.price * item.weight));
  }
}