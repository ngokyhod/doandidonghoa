import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'product_model.dart';

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
          String fullImgUrl = rawImg.startsWith('http') ? rawImg : '$domain/images/$rawImg';

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
}