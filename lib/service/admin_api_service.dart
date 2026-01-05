import 'dart:convert';
import 'package:http/http.dart' as http;
import '../service/ApiService.dart'; // Đảm bảo import đúng file chứa baseUrl

class AdminApiService {

  // ... (Các hàm cũ của bạn nếu có) ...

  // Hàm gọi Server để đồng bộ sản phẩm từ SQL -> Firebase
  static Future<bool> syncAllProducts() async {
    try {
      // API này nằm bên MobileApiController mà bạn đã viết trong Visual Studio
      final url = Uri.parse('${ApiService.baseUrl}/MobileApi/sync-products');

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
  static Future<bool> updateScrapStatus({
    required String requestId,
    required String status,
    String? date,
    double? weight,
  }) async {
    try {
      // Gọi sang MobileApiController (ApiService.baseUrl)
      final url = Uri.parse('${ApiService.baseUrl}/update-scrap-status');

      // KHAI BÁO RÕ LÀ Map<String, dynamic> ĐỂ CHỨA ĐƯỢC SỐ VÀ CHUỖI
      final Map<String, dynamic> bodyData = {
        "requestId": requestId,
        "status": status,
      };

      if (date != null) bodyData["date"] = date;
      if (weight != null) bodyData["actualWeight"] = weight;

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode != 200) {
        print("❌ Server Error: ${response.body}");
      }
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Lỗi API Thu Gom: $e");
      return false;
    }
  }
}