
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String title;
  final String imageUrl;
  final double price;
  final double quantity; // Chuyển sang double để hỗ trợ kg
  final String unit;
  final Map<String, String> selectedVariants;

  CartItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.unit,
    this.selectedVariants = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'selectedVariants': selectedVariants,
    };
  }

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      productId: data['productId'] ?? '',
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      selectedVariants: Map<String, String>.from(data['selectedVariants'] ?? {}),
    );
  }

  // Dùng cho API SQL
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? '',
      title: json['name'] ?? '',
      imageUrl: '', // Bạn có thể bổ sung nếu API SQL có ảnh
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['khoiluong'] ?? json['quantity'] ?? 0).toDouble(),
      unit: 'kg',
      selectedVariants: {},
    );
  }
}
