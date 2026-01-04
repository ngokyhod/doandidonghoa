import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../service/ApiService.dart';

class AdminApiService {
  static String get baseUrl {
    if (kIsWeb) return 'https://localhost:7240/api/AdminApi';
    return 'http://10.0.2.2:7240/api/AdminApi';
  }
  static Future<bool> syncAllProducts() async {
    try {
      // API này nằm bên MobileApiController mà bạn đã viết trong Visual Studio
      final url = Uri.parse('${ApiService.baseUrl}/sync-products');

      print("🔄 Đang gửi lệnh đồng bộ tới: $url");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Nếu cần token admin thì thêm vào đây: 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print("✅ Đồng bộ thành công: ${response.body}");
        return true;
      } else {
        print("❌ Lỗi Server: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Lỗi kết nối: $e");
      return false;
    }
  }
  // 1. Dashboard tổng quan
  static Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("❌ AdminApi Error (Dashboard): $e");
    }
    return null;
  }

  // 2. Danh sách đơn hàng
  static Future<List<dynamic>> getOrders({String status = "All"}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders?status=$status'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint("❌ AdminApi Error (Orders): $e");
    }
    return [];
  }

  static Future<bool> pushOrderStatus({
    required String orderId,
    required String status,
    String? carrier
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/update-order-status');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer $token", // Nếu có bảo mật
        },
        body: jsonEncode({
          "maDonHang": orderId,        // Phải khớp với DTO C#
          "trangThai": status,         // Phải khớp với DTO C#
          "donViVanChuyen": carrier    // (Tuỳ chọn)
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Đã push trạng thái lên Server thành công!");
        return true;
      } else {
        print("❌ Server trả lỗi: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối tới Visual Studio: $e");
      return false; // Trả về false để UI biết đường xử lý fallback
    }
  }

  // 4. Danh sách thu gom
  static Future<List<dynamic>> getCollections() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/collections'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint("❌ AdminApi Error (Collections): $e");
    }
    return [];
  }

  // 5. Danh sách sản phẩm
  static Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint("❌ AdminApi Error (Products): $e");
    }
    return [];
  }

  // --- MỚI: API QUẢN LÝ NGƯỜI DÙNG ---

  // Cập nhật thông tin/trạng thái khách hàng về SQL Server
  static Future<bool> syncUserUpdate(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/sync-update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ AdminApi Error (SyncUser): $e");
      return false;
    }
  }

  // Khóa tài khoản khách hàng
  static Future<bool> blockUser(String firebaseUid) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/block/$firebaseUid'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ AdminApi Error (BlockUser): $e");
      return false;
    }
  }
}
