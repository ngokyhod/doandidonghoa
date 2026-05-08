import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Thêm thư viện két sắt

class SyncService {
  // Khởi tạo két sắt bảo mật
  static const _storage = FlutterSecureStorage();

  // Cấu hình URL (Giống các Service khác)
  static String get baseUrl {
    if (kIsWeb) return 'https://localhost:7240/api/MobileApi';
    return 'http://10.0.2.2:5056/api/MobileApi';
  }

  // Hàm gọi chung để chạy tiến trình đồng bộ ngầm
  static Future<void> syncAll() async {
    print("🔄 Bắt đầu tiến trình đồng bộ ngầm...");

    // BƯỚC 1: ƯU TIÊN SYNC USER ĐẦU TIÊN
    await syncPendingUsers();

    // BƯỚC 2: SAU KHI SYNC USER XONG THÌ SYNC ĐƠN HÀNG & THU GOM
    await syncPendingScrapRequests();
    await syncPendingOrders();

    print("✅ Kết thúc tiến trình đồng bộ.");
  }

  // ==================================================================
  // --- 0. ĐỒNG BỘ TÀI KHOẢN (USER) LÊN SQL ---
  // ==================================================================
  // --- 0. ĐỒNG BỘ TÀI KHOẢN (USER) LÊN SQL ---
  static Future<void> syncPendingUsers() async {
    try {
      // B1: Lấy các user chưa đồng bộ, ưu tiên theo thời gian đăng ký (ai trước gửi trước)
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isSync', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      print("👤 Tìm thấy ${snapshot.docs.length} tài khoản cần đồng bộ...");

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        String uid = data['uid'] ?? doc.id;
        String email = data['email'] ?? '';
        String name = data['fullName'] ?? '';
        String phone = data['phone'] ?? '';
        String role = data['role'] ?? 'KhachHang';

        // B2: Lấy mật khẩu từ két sắt (chỉ lưu cục bộ ở máy)
        String? savedPass = await _storage.read(key: 'unsynced_pass_$uid');

        if (savedPass != null) {
          try {
            // ==============================================================
            // B3: TẠO PAYLOAD VÀ GỌI API (GIỐNG HỆT ĐƠN HÀNG VÀ THU GOM)
            // ==============================================================
            Map<String, dynamic> userPayload = {
              'FirebaseUid': uid,
              'Email': email,
              'FullName': name,
              'Phone': phone,
              'Password': savedPass,
              'Role': role
            };

            final response = await http.post(
              Uri.parse('$baseUrl/sync-user'), // Trỏ thẳng vào API C# của bạn
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(userPayload),   // Ép sang chuỗi JSON
            ).timeout(const Duration(seconds: 10));

            // B4: XỬ LÝ KẾT QUẢ TỪ VISUAL STUDIO TRẢ VỀ
            if (response.statusCode == 200) {
              // Thành công -> Cập nhật Firebase isSync = true
              await doc.reference.update({
                'isSync': true,
                'syncedAt': FieldValue.serverTimestamp(),
              });

              // QUAN TRỌNG: Đồng bộ xong phải xóa mật khẩu ngay để bảo mật
              await _storage.delete(key: 'unsynced_pass_$uid');
              print("✅ Đã đồng bộ Tài khoản lên SQL: $email");
            } else {
              print("❌ Lỗi API Tài khoản (${response.statusCode}): ${response.body}");
            }
          } catch (e) {
            print("⏳ Lỗi kết nối Tài khoản (Web có thể đang sập): $e");
          }
        } else {
          print("⚠️ User $uid chưa đồng bộ nhưng không tìm thấy pass trong máy. Bỏ qua.");
        }
      }
    } catch (e) {
      print("🔥 Lỗi hệ thống Sync Users: $e");
    }
  }

  // ==================================================================
  // --- 1. ĐỒNG BỘ ĐƠN HÀNG (Checkout) ---
  // ==================================================================
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

        // -------------------------------------------------------------
        // CHỐT CHẶN: Kiểm tra xem User của đơn này đã lên Web chưa?
        // -------------------------------------------------------------
        String uid = data['userId'] ?? data['uid'] ?? '';
        if (uid.isNotEmpty) {
          var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists && userDoc.data()?['isSync'] == false) {
            print("⏸️ Bỏ qua Đơn hàng ${doc.id} do Tài khoản ($uid) chưa đồng bộ xong.");
            continue; // Bỏ qua vòng lặp này, đơn hàng tiếp tục nằm chờ
          }
        }

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

  // ==================================================================
  // --- 2. ĐỒNG BỘ YÊU CẦU THU GOM (Scrap) ---
  // ==================================================================
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

        // -------------------------------------------------------------
        // CHỐT CHẶN: Kiểm tra xem User của yêu cầu này đã lên Web chưa?
        // -------------------------------------------------------------
        String uid = data['userId'] ?? data['uid'] ?? '';
        if (uid.isNotEmpty) {
          var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists && userDoc.data()?['isSync'] == false) {
            print("⏸️ Bỏ qua Thu gom ${doc.id} do Tài khoản ($uid) chưa đồng bộ xong.");
            continue; // Bỏ qua, chờ vòng lặp sau
          }
        }

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