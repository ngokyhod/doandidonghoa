import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

// --- 1. Model Đánh Giá (Review) ---
@freezed
class Review with _$Review {
  const factory Review({
    required String userName,
    required int rating,
    required String comment,
    required DateTime date,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);

  @override
  // TODO: implement comment
  String get comment => throw UnimplementedError();

  @override
  // TODO: implement date
  DateTime get date => throw UnimplementedError();

  @override
  // TODO: implement rating
  int get rating => throw UnimplementedError();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  // TODO: implement userName
  String get userName => throw UnimplementedError();
}

// --- 2. Model Biến Thể (Variant) ---
@freezed
class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required String name,
    required List<String> options,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);

  @override
  // TODO: implement name
  String get name => throw UnimplementedError();

  @override
  // TODO: implement options
  List<String> get options => throw UnimplementedError();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

// --- 3. Model Sản Phẩm (Product) ---
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
    @Default(0.0) double stockQuantity, // Đã đổi sang double
    @Default('') String category,
    @Default('') String sellerName,
    @Default('') String sellerId,
    @Default([]) List<Review> reviews,
  }) = _Product;

  // 1. Dùng cho Firebase
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    String imgUrl = data['imageUrls'] ?? data['anhSanPham'] ?? '';

    return Product(
      id: data['id']?.toString() ?? data['m_SanPham']?.toString() ?? doc.id,
      title: data['title'] ?? data['tenSanPham'] ?? 'Sản phẩm',
      price: (data['price'] ?? data['gia'] ?? 0).toDouble(),
      imageUrls: imgUrl.isNotEmpty ? [imgUrl] : [],
      category: data['category'] ?? data['tenLoai'] ?? '',
      unit: data['unit'] ?? data['tenDVT'] ?? 'kg',
      description: data['description'] ?? data['moTa'] ?? '',
      // Lấy từ nhiều nguồn key khác nhau để an toàn
      stockQuantity: (data['stock'] ?? data['totalStock'] ?? data['stockQuantity'] ?? 0).toDouble(),
    );
  }

  // 2. Dùng cho SQL (API Visual Studio)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['m_SanPham']?.toString() ?? json['id']?.toString() ?? '',
      title: json['tenSanPham'] ?? json['title'] ?? '',
      price: (json['gia'] ?? json['price'] ?? 0).toDouble(),
      unit: json['tenDVT'] ?? json['unit'] ?? 'kg',

      imageUrls: json['anhSanPham'] != null
          ? [json['anhSanPham']]
          : (json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : []),

      category: json['tenLoai'] ?? json['category'] ?? '',
      description: json['moTa'] ?? '',

      // Map từ API và ép kiểu double
      stockQuantity: (json['totalStock'] ?? json['stockQuantity'] ?? 0).toDouble(),

      reviews: (json['chiTietDanhGias'] as List<dynamic>?)
          ?.map((e) => Review(
        userName: e['tenKhachHang'] ?? e['userName'] ?? 'Ẩn danh',
        rating: int.tryParse(e['mucDoHaiLong']?.toString() ?? '') ?? 5,
        comment: e['moTa_DanhGia'] ?? e['comment'] ?? '',
        date: DateTime.tryParse(e['ngayDanhGia']?.toString() ?? '') ?? DateTime.now(),
      ))
          .toList() ?? const [],
    );
  }

  @override
  // TODO: implement category
  String get category => throw UnimplementedError();

  @override
  // TODO: implement description
  String get description => throw UnimplementedError();

  @override
  // TODO: implement id
  String get id => throw UnimplementedError();

  @override
  // TODO: implement imageUrls
  List<String> get imageUrls => throw UnimplementedError();

  @override
  // TODO: implement price
  double get price => throw UnimplementedError();

  @override
  // TODO: implement reviews
  List<Review> get reviews => throw UnimplementedError();

  @override
  // TODO: implement sellerId
  String get sellerId => throw UnimplementedError();

  @override
  // TODO: implement sellerName
  String get sellerName => throw UnimplementedError();

  @override
  // TODO: implement specifications
  Map<String, String> get specifications => throw UnimplementedError();

  @override
  // TODO: implement stockQuantity
  double get stockQuantity => throw UnimplementedError();

  @override
  // TODO: implement title
  String get title => throw UnimplementedError();

  @override
  // TODO: implement unit
  String get unit => throw UnimplementedError();

  @override
  // TODO: implement variants
  List<ProductVariant> get variants => throw UnimplementedError();
}