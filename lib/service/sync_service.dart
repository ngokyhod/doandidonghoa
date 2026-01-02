import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'CheckoutService.dart'; // Để lấy baseUrl

class SyncService {

  // Hàm này nên được gọi ở màn hình Home (initState) hoặc Splash Screen
  static Future<void> syncPendingOrders() async {
    print("🔄 Đang kiểm tra các đơn hàng chưa đồng bộ...");

    try {
      // 1. Lấy tất cả đơn hàng có isSync = false
      final snapshot = await FirebaseFirestore.instance
          .collection('DonHang')
          .where('isSync', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        print("✅ Không có đơn hàng nào cần đồng bộ.");
        return;
      }

      print("📦 Tìm thấy ${snapshot.docs.length} đơn hàng chưa đồng bộ. Bắt đầu đẩy lên Server...");

      for (var doc in snapshot.docs) {
        await _processSingleOrder(doc);
      }
    } catch (e) {
      print("❌ Lỗi tiến trình đồng bộ: $e");
    }
  }

  static Future<void> _processSingleOrder(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    // Lấy gói tin JSON mà ta đã backup lúc Checkout
    String? sqlPayload = data['sqlPayload'];

    if (sqlPayload == null) return; // Dữ liệu lỗi, bỏ qua

    try {
      // Gọi API SQL
      final response = await http.post(
        Uri.parse('${CheckoutService.baseUrl}/tao-don-hang'),
        headers: {'Content-Type': 'application/json'},
        body: sqlPayload,
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        String realOrderId = resData['maDonHang'];

        // CẬP NHẬT LẠI FIREBASE
        await FirebaseFirestore.instance.collection('DonHang').doc(doc.id).update({
          'isSync': true,
          'maDonHang': realOrderId, // Cập nhật mã thật (VD: DH00005)
          'trangThai': 'Chờ xác nhận', // Chuyển từ "Chờ đồng bộ" sang trạng thái thật
          'sqlPayload': FieldValue.delete() // Xóa payload đi cho sạch
        });

        print("✅ Đồng bộ thành công đơn: ${doc.id} -> $realOrderId");
      } else {
        print("⚠️ Đồng bộ thất bại đơn ${doc.id}: ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối khi đồng bộ đơn ${doc.id}: $e");
    }
  }
}