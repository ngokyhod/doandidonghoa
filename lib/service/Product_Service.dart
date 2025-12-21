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

  // Hàm lấy danh sách sản phẩm
  static Future<List<Product>> fetchProducts({String? query, String? category}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);

        List<Product> products = jsonList.map((jsonItem) {
          // Xử lý đường dẫn ảnh
          String rawImg = jsonItem['anhSanPham'] ?? '';
          // Nếu ảnh chưa có http đầu thì nối domain vào
          String domain = baseUrl.replaceAll('/api/MobileApi', '');
          String fullImgUrl = rawImg.startsWith('https') ? rawImg : '$domain/images/$rawImg';

          return Product(
            id: jsonItem['m_SanPham']?.toString() ?? '',
            title: jsonItem['tenSanPham'] ?? 'Không tên',
            price: (jsonItem['gia'] ?? 0).toDouble(),
            imageUrls: rawImg.isNotEmpty ? [fullImgUrl] : [],
            category: jsonItem['tenLoai'] ?? 'Khác',
            unit: jsonItem['tenDVT'] ?? '',
            description: jsonItem['moTa'] ?? '',
            sellerName: 'Cửa hàng',
            stockQuantity: 0,
          );
        }).toList();

        // Lọc dữ liệu bên Client (nếu API chưa hỗ trợ lọc)
        if (category != null && category != 'Tất cả') {
          products = products.where((p) => p.category == category).toList();
        }
        if (query != null && query.isNotEmpty) {
          products = products.where((p) =>
              p.title.toLowerCase().contains(query.toLowerCase())
          ).toList();
        }

        return products;
      } else {
        print('Lỗi Server: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Lỗi gọi API: $e');
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