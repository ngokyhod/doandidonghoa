import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'Product_Service.dart';
import 'package:image_picker/image_picker.dart';
class ChatService {
  // Đồng bộ URL với ProductService (tự động chọn 10.0.2.2 hoặc localhost)
  static String get baseUrl {
    if (kIsWeb) return 'http://192.168.1.131:5000';
    return 'http://192.168.1.131:5000'; // Dùng 10.0.2.2 cho Android Emulator
  }

  // 1. Gửi tin nhắn Text
  static Future<String> sendMessage(String message) async {
    try {
      final uri = Uri.parse('$baseUrl/predict');
      print('--- Đang gửi đến: $uri ---'); // Debug 1

      final response = await http.post(
        uri,
        // Thêm headers để đảm bảo server hiểu form data
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'message': message},
      );

      print('Status Code: ${response.statusCode}'); // Debug 2
      print('Body nhận được: ${response.body}');    // Debug 3: Quan trọng nhất!

      if (response.statusCode == 200) {
        // Thử decode JSON
        try {
          // Xử lý trường hợp chuỗi bị lỗi encoding (dấu tiếng Việt)
          String bodyUtf8 = utf8.decode(response.bodyBytes);
          final data = json.decode(bodyUtf8);
          return data['response'] ?? "Server không trả về 'response'";
        } catch (e) {
          print("Lỗi JSON Decode: $e");
          return "Lỗi đọc dữ liệu: $e";
        }
      }
      return "Lỗi server: ${response.statusCode}";
    } catch (e) {
      print("Lỗi kết nối: $e");
      return "Lỗi kết nối: $e";
    }
  }

  // 2. Gửi ảnh (LƯU Ý QUAN TRỌNG Ở DƯỚI)
  static Future<String> sendImage(XFile file) async {
    try {
      final uri = Uri.parse('https://localhost:7240/api/chat/upload');
      var request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        // --- LOGIC CHO WEB (Đọc Bytes) ---
        // Trên web không dùng path được, phải đọc dữ liệu byte
        var bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file', // Tên biến khớp với C#
          bytes,
          filename: file.name, // Gửi kèm tên file để C# biết đuôi .jpg/.png
        ));
      } else {
        // --- LOGIC CHO MOBILE (Dùng Path) ---
        request.files.add(await http.MultipartFile.fromPath(
            'file',
            file.path
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reply'] ?? "Không nhận diện được ảnh.";
      }
      return "Lỗi Server (${response.statusCode}): ${response.body}";
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }
}
