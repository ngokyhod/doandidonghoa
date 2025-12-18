
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


  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final imageUrlsData = data['imageUrls'] as List?;
    final List<String> imageUrls = imageUrlsData?.map((e) => e.toString()).toList() ?? [];
    if (imageUrls.isEmpty && (data['imageUrl'] is String && (data['imageUrl'] as String).isNotEmpty)) {
      imageUrls.add(data['imageUrl']);
    }

    final variantsData = data['variants'] as List? ?? [];
    final variants = variantsData.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>)).toList();
    
    final specificationsData = data['specifications'] as Map?;
    final specifications = specificationsData?.map((key, value) => MapEntry(key.toString(), value.toString())) ?? {};

    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      imageUrls: imageUrls,
      description: data['description'] ?? '',
      specifications: specifications,
      variants: variants,
      stockQuantity: data['stockQuantity'] ?? 0,
      category: data['category'] ?? '',
      sellerName: data['sellerName'] ?? 'Ẩn danh',
      sellerId: data['sellerId'] ?? '',
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
