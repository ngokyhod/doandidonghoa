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
  static Future<bool> deleteProduct(String productId) async {
    try {
      print("🗑️ Đang gửi lệnh xóa tới SQL: $productId");

      // B1: Gọi API Xóa bên SQL
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'), // Bạn cần viết API Delete bên C#
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // B2: Nếu SQL xóa thành công -> Xóa trên Firebase
        await FirebaseFirestore.instance.collection('Products').doc(productId).delete();
        // Xóa luôn trong collection 'SanPham' nếu bạn dùng song song
        // await FirebaseFirestore.instance.collection('SanPham').doc(productId).delete();

        print("✅ Đã xóa thành công cả SQL và Firebase");
        return true;
      } else {
        print("❌ Lỗi SQL: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối (Server tắt): $e");
      return false; // Trả về false để UI báo lỗi
    }
  }

  // --- 2. HÀM CẬP NHẬT SẢN PHẨM (Yêu cầu Visual Studio Online) ---
  static Future<bool> updateProduct(Product product) async {
    try {
      print("✏️ Đang gửi lệnh sửa tới SQL: ${product.id}");

      // Map Model sang JSON của C# (DTO)
      final Map<String, dynamic> sqlData = {
        "M_SanPham": product.id,
        "TenSanPham": product.title,
        "Gia": product.price,
        "MoTa": product.description,
        "M_Loai": product.category, // Lưu ý: API C# cần xử lý nhận Mã hoặc Tên
        // "HinhAnh": ... (Xử lý ảnh cập nhật hơi phức tạp, tạm thời bỏ qua nếu chưa cần)
      };

      // B1: Gọi API Update bên SQL
      final response = await http.put(
        Uri.parse('$baseUrl/products/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sqlData),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // B2: SQL thành công -> Cập nhật Firebase
        // Chỉ cập nhật các trường thay đổi
        await FirebaseFirestore.instance.collection('Products').doc(product.id).update({
          'tenSanPham': product.title,
          'gia': product.price,
          'moTa': product.description,
          'category': product.category,
          'lastUpdated': FieldValue.serverTimestamp()
        });

        print("✅ Đã cập nhật thành công");
        return true;
      } else {
        print("❌ Lỗi SQL: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối Update: $e");
      return false;
    }
  }
}