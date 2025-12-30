import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

class CartItem {
  final Product product; // Đối tượng sản phẩm gốc
  double weight;         // Khối lượng mua (tương ứng quantity)

  CartItem({
    required this.product,
    required this.weight,
  });

  // --- CÁC GETTER TIỆN ÍCH (Để tương thích với code cũ & UI) ---
  String get productId => product.id;
  String get title => product.title;
  double get price => product.price;

  // Lấy ảnh đầu tiên, nếu không có trả về rỗng
  String get imageUrl => (product.imageUrls.isNotEmpty)
      ? product.imageUrls.first
      : '';

  // CheckoutScreen gọi quantity, ta map nó vào weight
  double get quantity => weight;

  // --- 1. CHUYỂN ĐỔI SANG MAP (Để lưu Firebase/API) ---
  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'title': product.title,
      'imageUrl': imageUrl, // Lưu link ảnh đại diện
      'price': product.price,
      'quantity': weight,   // Lưu khối lượng vào trường quantity của DB
      'unit': product.unit, // Lấy đơn vị từ sản phẩm
      // Bỏ selectedVariants nếu không dùng nữa
    };
  }

  // --- 2. ĐỌC TỪ FIRESTORE ---
  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Vì CartItem bắt buộc phải có Product, ta tạo một Product "giả" từ dữ liệu đã lưu
    // để đảm bảo code không bị lỗi null.
    Product tempProduct = Product(
      id: data['productId'] ?? '',
      title: data['title'] ?? 'Sản phẩm',
      price: (data['price'] ?? 0).toDouble(),
      imageUrls: data['imageUrl'] != null ? [data['imageUrl']] : [],
      category: '', // Không lưu trên Cart nên để rỗng
      unit: data['unit'] ?? 'kg',
      description: '',
      stockQuantity: 0,
    );

    return CartItem(
      product: tempProduct,
      weight: (data['quantity'] ?? 0).toDouble(),
    );
  }

  // --- 3. ĐỌC TỪ API SQL (JSON) ---
  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Tạo Product tạm từ JSON API
    Product tempProduct = Product(
      id: json['productId'] ?? '',
      title: json['name'] ?? json['title'] ?? '', // API có thể trả về 'name' hoặc 'title'
      price: (json['price'] ?? 0).toDouble(),
      imageUrls: [], // Nếu API giỏ hàng không trả ảnh thì để rỗng hoặc load sau
      category: '',
      unit: json['unit'] ?? 'kg',
      description: '',
      stockQuantity: 0,
    );

    return CartItem(
      product: tempProduct,
      weight: (json['khoiluong'] ?? json['quantity'] ?? 0).toDouble(),
    );
  }
}