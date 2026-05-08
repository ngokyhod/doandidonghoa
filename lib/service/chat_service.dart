import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ChatService {
  // Đường dẫn tới Server Python
  static String get baseUrl {
    return 'http://192.168.1.131:5000';
  }

  // SỬ DỤNG STREAM ĐỂ AI GÕ RA TỪNG CHỮ NHƯ CHATGPT
  static Stream<String> sendMessageStream(String text, {XFile? image}) async* {
    final uri = Uri.parse('$baseUrl/chat');
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json; charset=UTF-8';

    // 1. Mã hóa ảnh thành Base64
    String? base64Image;
    if (image != null) {
      final bytes = await image.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    // 2. Gói dữ liệu
    request.body = jsonEncode({
      'session_id': 'mobile_session',
      'question': text.isEmpty ? "Nhận diện hình ảnh này" : text,
      'image': base64Image
    });

    try {
      final client = http.Client();
      // 3. Gửi Request và chờ (Tăng timeout lên 6 phút cho AI RAG)
      final response = await client.send(request).timeout(const Duration(minutes: 6));

      if (response.statusCode == 200) {
        // 4. Lắng nghe và đẩy từng chữ (chunk) về cho giao diện
        await for (var chunk in response.stream.transform(utf8.decoder)) {
          yield chunk;
        }
      } else {
        yield "Lỗi server: ${response.statusCode}";
      }
    } catch (e) {
      yield "Lỗi kết nối Stream: $e";
    }
  }
}