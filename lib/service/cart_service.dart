import '../model/product_model.dart';
import '../model/cart_item_model.dart';


class CartService {
  // Dùng static list để lưu tạm trong bộ nhớ (khi tắt app sẽ mất).
  // Nếu muốn lưu lâu dài cần dùng SQLite hoặc Firestore.
  static final List<CartItem> _cartItems = [];

  static List<CartItem> get cartItems => _cartItems;

  static void addToCart(Product product, double weight) {
    // Kiểm tra xem sản phẩm đã có trong giỏ chưa
    final index = _cartItems.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      // Nếu có rồi thì cộng dồn khối lượng
      _cartItems[index].weight += weight;
    } else {
      // Chưa có thì thêm mới (Dùng CartItem của Model)
      _cartItems.add(CartItem(product: product, weight: weight));
    }
  }

  static void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
    }
  }

  static void clearCart() {
    _cartItems.clear();
  }

  static double getTotalPrice() {
    return _cartItems.fold(0, (sum, item) => sum + (item.product.price * item.weight));
  }
}