import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../model/product_model.dart';

class ProductService {
  // Cấu hình địa chỉ API
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://localhost:7240/api/MobileApi'; // Nếu chạy Web
    } else {
      // Nếu chạy máy ảo Android thì dùng 10.0.2.2
      // Nếu chạy điện thoại thật thì thay bằng IP máy tính (vd: 192.168.1.x)
      return 'http://10.0.2.2:5056/api/MobileApi';
    }
  }
  static String get baseImageUrl {
    if (kIsWeb) return 'https://localhost:7240';
    return 'http://10.0.2.2:5136';
  }
  // Hàm lấy danh sách sản phẩm
  static Future<List<Product>> fetchProducts({String? query, String? category}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // 1. Map dữ liệu từ JSON sang List<Product>
        List<Product> allProducts = data.map((jsonItem) {
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
            // Đảm bảo lấy đúng tên loại từ API để lọc
            category: jsonItem['tenLoai'] ?? '',
            unit: jsonItem['tenDVT'] ?? 'kg',
            description: jsonItem['moTa'] ?? '',
            stockQuantity: 0,
          );
        }).toList();

        // 2. THỰC HIỆN LỌC (FILTERING) TẠI ĐÂY
        return allProducts.where((product) {
          // A. Lọc theo từ khóa tìm kiếm (Search)
          bool matchQuery = true;
          if (query != null && query.isNotEmpty) {
            matchQuery = product.title.toLowerCase().contains(query.toLowerCase());
          }

          // B. Lọc theo danh mục (Category)
          bool matchCategory = true;
          if (category != null && category != 'Tất cả') {
            // So sánh tên loại sản phẩm (Ví dụ: "Phân bón" == "Phân bón")
            // Dùng toLowerCase() để so sánh không phân biệt hoa thường cho chắc chắn
            matchCategory = product.category.toLowerCase() == category.toLowerCase();
          }

          return matchQuery && matchCategory;
        }).toList();

      } else {
        print('Lỗi server: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Lỗi kết nối fetchProducts: $e');
      return [];
    }
  }
  // Hàm lấy chi tiết sản phẩm
  static Future<Product?> fetchProductDetail(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id'));

      if (response.statusCode == 200) {
        final jsonItem = json.decode(response.body);

        // Xử lý ảnh
        String rawImg = jsonItem['anhSanPham'] ?? '';
        // Lưu ý: Nếu ảnh là đường dẫn tương đối, cần ghép domain vào
        String fullImgUrl = rawImg.startsWith('http') ? rawImg : '${baseUrl.replaceAll("/api/MobileApi", "")}/$rawImg'; // Logic ghép ảnh tùy server của bạn

        // Xử lý đánh giá (Giả sử API trả về list đánh giá, nếu chưa có thì để rỗng)
        List<Review> reviewsList = [];
        if (jsonItem['chiTietDanhGias'] != null) {
          reviewsList = (jsonItem['chiTietDanhGias'] as List).map((r) => Review(
            userName: r['tenKhachHang'] ?? 'Ẩn danh',
            rating: int.tryParse(r['mucDoHaiLong'].toString()) ?? 5,
            comment: r['moTa_DanhGia'] ?? '',
            date: DateTime.tryParse(r['ngayDanhGia']) ?? DateTime.now(),
          )).toList();
        }

        return Product(
          id: jsonItem['m_SanPham']?.toString() ?? '',
          title: jsonItem['tenSanPham'] ?? '',
          price: (jsonItem['gia'] ?? 0).toDouble(),
          imageUrls: rawImg.isNotEmpty ? [fullImgUrl] : [],
          category: jsonItem['tenLoai'] ?? '',
          unit: jsonItem['tenDVT'] ?? 'kg', // Đơn vị tính
          description: jsonItem['moTa'] ?? '',
          stockQuantity: (jsonItem['totalStock'] ?? 0).toInt(), // Tồn kho
          reviews: reviewsList,
          sellerName: 'Cửa hàng',
        );
      }
    } catch (e) {
      print('Lỗi lấy chi tiết: $e');
    }
    return null;
  }
  static Future<List<Product>> fetchRelatedProducts(String category, String currentProductId) async {
    try {
      // Vì API chưa có endpoint lọc riêng, ta lấy hết về rồi lọc ở Client (Tạm thời)
      // Nếu dữ liệu lớn, sau này bạn nên viết API riêng: /products?category=...
      final allProducts = await fetchProducts();

      return allProducts
          .where((p) => p.category == category && p.id != currentProductId) // Cùng loại & khác bài hiện tại
          .take(6) // Chỉ lấy tối đa 6 sản phẩm
          .toList();
    } catch (e) {
      print('Lỗi lấy sản phẩm liên quan: $e');
      return [];
    }
  }
}