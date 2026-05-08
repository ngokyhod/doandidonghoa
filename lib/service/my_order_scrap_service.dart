import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MyOrderScrapService {
  // Thay port 7240 thành port của máy chủ C# của bạn
  static final String serverBaseUrl = kIsWeb ? 'https://localhost:7240' : 'https://10.0.2.2:7240';

  // Hàm bỏ qua lỗi chứng chỉ SSL trên máy ảo Android
  static void initHttpOverrides() {
    HttpOverrides.global = _DevHttpOverrides();
  }

  // LẤY DANH SÁCH ĐƠN HÀNG
  Future<List<Map<String, dynamic>>> fetchOrders(String userId) async {
    final url = Uri.parse('$serverBaseUrl/api/MobileApi/orders/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Lỗi fetchOrders: $e");
    }
    return [];
  }

  // LẤY DANH SÁCH THU GOM
  Future<List<Map<String, dynamic>>> fetchScrapRequests(String userId) async {
    final url = Uri.parse('$serverBaseUrl/api/MobileApi/scrap-requests/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Lỗi fetchScrapRequests: $e");
    }
    return [];
  }
}

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}