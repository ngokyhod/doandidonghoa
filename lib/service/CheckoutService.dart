import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../model/cart_item_model.dart';

class CheckoutService {

  static String get baseUrl {
    if (kIsWeb) {
      return 'https://localhost:7240/api/MobileApi';
    } else {
      return 'http://10.0.2.2:5056/api/MobileApi';
    }
  }

  static Future<bool> createOrder({
    required String uid,
    required String hoTen,
    required String sdt,
    required String diaChi,
    required String ghiChu,
    required String phuongThucThanhToan,
    required double tongTien,
    required List<CartItem> cartItems,
  }) async {

    // 1. Chuẩn bị dữ liệu SQL (Cho dù có gửi được hay không cũng cần chuẩn bị format này)
    final Map<String, dynamic> sqlData = {
      "UserId": uid,
      "Tendathang": hoTen,
      "SoDienThoaidathang": sdt,
      "ShippingAddress": diaChi,
      "Notes": ghiChu,
      "M_PhuongThuc": phuongThucThanhToan,
      "TongTien": tongTien,
      "NgayDat": DateTime.now().toIso8601String(),
      "ChiTietDonHangs": cartItems.map((item) {
        return {
          "M_SanPham": item.productId,
          "TenSanPham": item.title,
          "SoLuong": item.weight,
          "DonGia": item.price
        };
      }).toList()
    };

    // 2. Chuẩn bị dữ liệu Firebase
    final Map<String, dynamic> firebaseData = {
      'uid': uid,
      'maDonHang': 'PENDING', // Tạm thời chưa có mã từ SQL
      'ngayDat': FieldValue.serverTimestamp(),
      'trangThai': 'Chờ đồng bộ', // Trạng thái tạm
      'trangThaiThanhToan': 'Chưa thanh toán',
      'tongTien': tongTien,
      'nguoiNhan': {
        'ten': hoTen,
        'sdt': sdt,
        'diaChi': diaChi
      },
      'items': cartItems.map((item) => {
        'ten': item.title,
        'anh': item.imageUrl,
        'gia': item.price,
        'soLuong': item.weight,
        'productId': item.productId // Lưu lại ID để sau này sync
      }).toList(),

      // --- CỜ QUAN TRỌNG ---
      'isSync': false, // Mặc định là chưa đồng bộ
      'sqlPayload': jsonEncode(sqlData) // LƯU LUÔN GÓI TIN CẦN GỬI API VÀO FIREBASE ĐỂ DÙNG LẠI SAU
    };

    try {
      print("🚀 Đang thử gửi đơn hàng tới SQL...");

      // BƯỚC A: Thử gọi API SQL
      final response = await http.post(
        Uri.parse('$baseUrl/tao-don-hang'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sqlData),
      ).timeout(const Duration(seconds: 10)); // Timeout 10s để không đợi lâu

      if (response.statusCode == 200) {
        // --- TRƯỜNG HỢP 1: API THÀNH CÔNG (Lý tưởng) ---
        final responseData = jsonDecode(response.body);
        String maDonHangSQL = responseData['maDonHang'] ?? "DH_Unknown";

        // Cập nhật dữ liệu Firebase thành chuẩn
        firebaseData['isSync'] = true;
        firebaseData['maDonHang'] = maDonHangSQL;
        firebaseData['trangThai'] = 'Chờ xác nhận';
        // Xóa payload đi cho nhẹ db vì đã sync xong
        firebaseData.remove('sqlPayload');

        await FirebaseFirestore.instance.collection('DonHang').add(firebaseData);
        print("✅ Đã lưu SQL & Firebase (Sync: True)");
        return true;
      } else {
        // --- TRƯỜNG HỢP 2: API LỖI (Server 500, 400...) ---
        print("⚠️ API Lỗi ${response.statusCode}. Chuyển sang lưu Offline.");
        throw Exception("API Error"); // Ném lỗi để nhảy xuống catch
      }
    } catch (e) {
      // --- TRƯỜNG HỢP 3: MẤT MẠNG HOẶC SERVER CHẾT ---
      print("⚠️ Không kết nối được SQL: $e. Đang lưu tạm vào Firebase...");

      // Vẫn lưu vào Firebase nhưng isSync = false
      // Giữ nguyên 'sqlPayload' để service đồng bộ sau này dùng
      await FirebaseFirestore.instance.collection('DonHang').add(firebaseData);

      print("✅ Đã lưu Firebase (Sync: False) - Sẽ đồng bộ lại sau.");
      return true; // Vẫn trả về true để App báo "Đặt hàng thành công" cho khách vui
    }
  }
}