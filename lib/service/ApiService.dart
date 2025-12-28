import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // kIsWeb

class ApiService {
  // Cấu hình URL (Sửa lại Port của bạn)
  static String get baseUrl {
    if (kIsWeb) return 'https://localhost:7240/api/MobileApi';
    return 'http://10.0.2.2:7240/api/MobileApi';
  }

  // 1. PUSH: Gửi thông tin đăng ký sang Visual
  static Future<bool> syncUserToBackend(String uid, String email, String name, String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'FirebaseUid': uid,
          'FullName': name,
          'Email': email,
          'Phone': phone,
          'Password': password
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Đồng bộ sang SQL Server thành công!");
        return true;
      } else {
        print("❌ Lỗi Server: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Lỗi kết nối API: $e");
      return false;
    }
  }

  // 2. PULL: Lấy thông tin từ Visual về App
  static Future<Map<String, dynamic>?> getUserProfile(String firebaseUid) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-profile/$firebaseUid'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi lấy profile: $e");
    }
    return null;
  }

}