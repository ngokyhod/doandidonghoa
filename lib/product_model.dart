
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required String name, 
    required List<String> options, 
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);
}

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String title,
    required double price,
    required String unit,
    @Default([]) List<String> imageUrls,
    @Default('') String description,
    @Default({}) Map<String, String> specifications,
    @Default([]) List<ProductVariant> variants,
    @Default(0) int stockQuantity,
    @Default('') String category,
    @Default('') String sellerName,
    @Default('') String sellerId,
  }) = _Product;

  // 1. Dùng cho Firebase
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'] ?? '',
      sellerName: data['sellerName'] ?? 'Saika Hana',
    );
  }

  // 2. Dùng cho SQL (Khớp với Controller C# của bạn)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['m_SanPham'] ?? json['id'] ?? '',
      title: json['tenSanPham'] ?? json['title'] ?? '',
      price: (json['gia'] ?? json['price'] ?? 0).toDouble(),
      unit: json['donViTinh']?['tenDVT'] ?? 'kg',
      imageUrls: [json['anhSanPham'] ?? json['imageUrl'] ?? ''],
      category: json['loaiSanPham']?['tenLoai'] ?? '',
      description: json['moTa'] ?? '',
      stockQuantity: (json['totalStock'] ?? 0).toInt(),
    );
  }
}
