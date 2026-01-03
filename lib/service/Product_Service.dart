import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../model/product_model.dart';
import 'ApiService.dart'; // Sử dụng ApiService chung nếu có, hoặc dùng biến static bên dưới

class ProductService {

  // Cấu hình URL
  static String get baseUrl {
    if (kIsWeb) return 'https://localhost:7240/api/MobileApi';
    return 'http://10.0.2.2:5056/api/MobileApi';
  }

  static String get baseImageUrl {
    if (kIsWeb) return 'https://localhost:7240';
    return 'http://10.0.2.2:5136';
  }

  // --- HÀM LẤY SẢN PHẨM (API -> FIREBASE) ---
  static Future<List<Product>> fetchProducts({String? query, String? category}) async {
    List<Product> products = [];

    // 1. THỬ GỌI API TRƯỚC
    try {
      print("🌐 Đang kết nối API lấy sản phẩm...");
      final response = await http.get(Uri.parse('$baseUrl/products'))
          .timeout(const Duration(seconds: 3)); // Timeout nhanh (3s)

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        products = data.map((jsonItem) {
          // Xử lý ảnh từ API
          String rawImg = jsonItem['anhSanPham'] ?? '';
          String fullImgUrl = '';
          if (rawImg.isNotEmpty) {
            fullImgUrl = rawImg.startsWith('http') ? rawImg : '$baseImageUrl/$rawImg';
          }

          return Product(
            id: jsonItem['m_SanPham'] ?? '',
            title: jsonItem['tenSanPham'] ?? '',
            price: (jsonItem['gia'] ?? 0).toDouble(),
            imageUrls: fullImgUrl.isNotEmpty ? [fullImgUrl] : [],
            category: jsonItem['tenLoai'] ?? '',
            unit: jsonItem['tenDVT'] ?? 'kg',
            description: jsonItem['moTa'] ?? '',
            stockQuantity: (jsonItem['totalStock'] ?? 0).toDouble(),
          );
        }).toList();

        print("✅ Lấy từ API thành công: ${products.length} sản phẩm.");
      } else {
        throw Exception('API lỗi ${response.statusCode}');
      }
    } catch (e) {
      // 2. NẾU API LỖI -> GỌI FIREBASE
      print("⚠️ API lỗi/mất kết nối: $e");
      print("🔥 Chuyển sang lấy dữ liệu Offline từ Firebase...");
      products = await _fetchFromFirebase();
    }

    // 3. ÁP DỤNG BỘ LỌC (CHUNG CHO CẢ 2 NGUỒN)
    // Logic lọc này áp dụng cho cả list từ API hoặc list từ Firebase
    return products.where((product) {
      // A. Lọc theo từ khóa (Search)
      bool matchQuery = true;
      if (query != null && query.isNotEmpty) {
        matchQuery = product.title.toLowerCase().contains(query.toLowerCase());
      }

      // B. Lọc theo danh mục (Category)
      bool matchCategory = true;
      if (category != null && category != 'Tất cả') {
        matchCategory = product.category.toLowerCase() == category.toLowerCase();
      }

      return matchQuery && matchCategory;
    }).toList();
  }

  // --- HÀM PHỤ: LẤY TỪ FIREBASE ---
  static Future<List<Product>> _fetchFromFirebase() async {
    try {
      // LƯU Ý: Tên Collection phải khớp với code C# FirebaseSyncService ("Products")
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('SanPham')
          .get();

      print("✅ Lấy từ Firebase được: ${snapshot.docs.length} dòng.");

      return snapshot.docs.map((doc) {
        // Gọi hàm factory từ Model để map dữ liệu
        return Product.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print("❌ Lỗi Firebase: $e");
      return [];
    }
  }

  // --- HÀM CHI TIẾT SẢN PHẨM (CŨNG NÊN CÓ FALLBACK) ---
  static Future<Product?> fetchProductDetail(String id) async {
    // 1. Thử API
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final jsonItem = json.decode(response.body);

        // Xử lý ảnh
        String rawImg = jsonItem['anhSanPham'] ?? '';
        String fullImgUrl = rawImg.startsWith('http') ? rawImg : '$baseImageUrl/$rawImg';

        // Map đánh giá
        List<Review> reviewsList = [];
        if (jsonItem['chiTietDanhGias'] != null) {
          reviewsList = (jsonItem['chiTietDanhGias'] as List).map((r) => Review(
            userName: r['tenKhachHang'] ?? 'Ẩn danh',
            rating: int.tryParse(r['mucDoHaiLong'].toString()) ?? 5,
            comment: r['moTa_DanhGia'] ?? '',
            date: DateTime.tryParse(r['ngayDanhGia'] ?? '') ?? DateTime.now(),
          )).toList();
        }

        return Product(
          id: jsonItem['m_SanPham']?.toString() ?? '',
          title: jsonItem['tenSanPham'] ?? '',
          price: (jsonItem['gia'] ?? 0).toDouble(),
          imageUrls: rawImg.isNotEmpty ? [fullImgUrl] : [],
          category: jsonItem['tenLoai'] ?? '',
          unit: jsonItem['tenDVT'] ?? 'kg',
          description: jsonItem['moTa'] ?? '',
          stockQuantity: (jsonItem['totalStock'] ?? 0).toInt(),
          reviews: reviewsList,
          sellerName: 'Cửa hàng',
        );
      }
    } catch (e) {
      print("⚠️ Lỗi API chi tiết: $e. Thử lấy từ Firebase...");
    }

    // 2. Fallback Firebase (Nếu API lỗi)
    try {
      // Tìm trong collection Products đúng ID này
      // Lưu ý: ID document trên Firebase chính là m_SanPham
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Products')
          .doc(id)
          .get();

      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
    } catch (e) {
      print("❌ Lỗi chi tiết Firebase: $e");
    }

    return null;
  }
}