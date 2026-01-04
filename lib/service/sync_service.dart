import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SyncService {

  // Cấu hình URL (Giống các Service khác)
  static String get baseUrl {
    if (kIsWeb) return 'https://localhost:7240/api/MobileApi';
    return 'http://10.0.2.2:5056/api/MobileApi';
  }

  // Hàm gọi chung để chạy cả 2 tiến trình đồng bộ
  static Future<void> syncAll() async {
    print("🔄 Bắt đầu tiến trình đồng bộ ngầm...");await syncPendingScrapRequests();
    await syncPendingOrders();

    print("✅ Kết thúc tiến trình đồng bộ.");
  }

  // --- 1. ĐỒNG BỘ ĐƠN HÀNG (Checkout) ---
  static Future<void> syncPendingOrders() async {
    try {
      // B1: Lấy các đơn hàng chưa đồng bộ từ Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('DonHang')
          .where('isSync', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      print("📦 Tìm thấy ${snapshot.docs.length} đơn hàng cần đồng bộ...");

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();

        // QUAN TRỌNG: Lấy gói tin JSON chuẩn đã lưu lúc Checkout
        // Gói này chứa đúng các key mà C# cần: UserId, ChiTietDonHangs...
        String? payload = data['sqlPayload'];

        if (payload == null || payload.isEmpty) {
          print("⚠️ Đơn hàng ${doc.id} lỗi: Không có sqlPayload. Bỏ qua.");
          continue;
        }

        try {
          // B2: Gửi nguyên gói tin này lên API SQL
          final response = await http.post(
            Uri.parse('$baseUrl/tao-don-hang'),
            headers: {'Content-Type': 'application/json'},
            body: payload, // Gửi chuỗi JSON gốc
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final resJson = jsonDecode(response.body);
            String maDonHangSQL = resJson['maDonHang'] ?? "DH_Unknown";

            // B3: API thành công -> Cập nhật Firestore
            await doc.reference.update({
              'isSync': true,
              'maDonHang': maDonHangSQL, // Cập nhật mã thật từ SQL
              'trangThai': 'Chờ xác nhận', // Đổi trạng thái từ "Chờ đồng bộ" -> "Chờ xác nhận"
              'sqlPayload': FieldValue.delete() // Xóa payload cho nhẹ database vì đã xong nhiệm vụ
            });
            print("✅ Đã đồng bộ Đơn hàng lên SQL: $maDonHangSQL");
          } else {
            print("❌ Lỗi API Đơn hàng (${response.statusCode}): ${response.body}");
          }
        } catch (e) {
          print("⏳ Lỗi kết nối Đơn hàng (Server có thể vẫn tắt): $e");
          // Không làm gì cả, để lần sau chạy tiếp
        }
      }
    } catch (e) {
      print("🔥 Lỗi hệ thống Sync Orders: $e");
    }
  }

  // --- 2. ĐỒNG BỘ YÊU CẦU THU GOM (Scrap) ---
  static Future<void> syncPendingScrapRequests() async {
    try {
      // B1: Lấy các yêu cầu chưa đồng bộ
      final snapshot = await FirebaseFirestore.instance
          .collection('ThuGom')
          .where('isSync', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      print("♻️ Tìm thấy ${snapshot.docs.length} yêu cầu thu gom cần đồng bộ...");

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();

        // Lấy gói tin JSON chuẩn C# (HoTen, SoDienThoai, KhoiLuong...)
        String? payload = data['sqlPayload'];

        if (payload == null || payload.isEmpty) continue;

        try {
          // B2: Gửi lên API SQL
          final response = await http.post(
            Uri.parse('$baseUrl/tao-yeu-cau-thu-gom'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final resJson = jsonDecode(response.body);

            // B3: Thành công -> Cập nhật Firestore
            await doc.reference.update({
              'isSync': true,
              'maYeuCauSQL': resJson['maYeuCau'], // Lưu mã từ SQL trả về
              'trangThaiXuLy': 'MoiYeuCau', // Trạng thái chính thức
              'sqlPayload': FieldValue.delete()
            });
            print("✅ Đã đồng bộ Thu Gom lên SQL: ${doc.id}");
          } else {
            print("❌ Lỗi API Thu Gom (${response.statusCode}): ${response.body}");
          }
        } catch (e) {
          print("⏳ Lỗi kết nối Thu Gom: $e");
        }
      }
    } catch (e) {
      print("🔥 Lỗi hệ thống Sync Scrap: $e");
    }
  }
}