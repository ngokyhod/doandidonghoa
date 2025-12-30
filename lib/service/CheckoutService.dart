import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../model/cart_item_model.dart'; // Import model giỏ hàng

class CheckoutService {

  // 1. Cấu hình Base URL (Tái sử dụng logic cũ)
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://localhost:7240/api/MobileApi';
    } else {
      // ANDROID EMULATOR DÙNG 10.0.2.2
      // MÁY THẬT DÙNG IP LAN (VD: 192.168.1.X)
      return 'http://10.0.2.2:5056/api/MobileApi';
    }
  }

  // 2. Hàm xử lý Checkout (Gọi cả Firebase và SQL)
  static Future<bool> createOrder({
    required String uid,
    required String hoTen,
    required String sdt,
    required String diaChi,
    required String ghiChu,
    required String phuongThucThanhToan, // Mã phương thức (PT001, PT005...)
    required double tongTien,
    required List<CartItem> cartItems,
  }) async {

    // --- CHUẨN BỊ DỮ LIỆU ---
    // Tạo mã đơn hàng trên App hoặc để Server tự sinh (Ở đây để Server sinh cho chuẩn)
    final now = DateTime.now();

    // Map danh sách sản phẩm sang định dạng JSON đơn giản
    final List<Map<String, dynamic>> chiTietDonHang = cartItems.map((item) => {
      'productId': item.productId,
      'productName': item.title,
      'quantity': item.weight, // Trong hệ thống của bạn: số lượng = khối lượng (kg)
      'price': item.price,
      'imageUrl': item.imageUrl,
    }).toList();

    // Dữ liệu dùng cho Firebase (Hiển thị App)
    final firebaseData = {
      'uid': uid,
      'ngayDat': FieldValue.serverTimestamp(),
      'trangThai': 'Chờ xử lý',
      'trangThaiThanhToan': 'Chưa thanh toán',
      'tenNguoiNhan': hoTen,
      'sdtNguoiNhan': sdt,
      'diaChiGiaoHang': diaChi,
      'ghiChu': ghiChu,
      'phuongThucTT': phuongThucThanhToan, // Lưu mã hoặc tên đều được
      'tongTien': tongTien,
      'items': chiTietDonHang, // Lưu mảng sản phẩm vào document
    };

    // Dữ liệu dùng cho SQL Server (Khớp với DonHangDto bên C#)
    final sqlData = {
      'UserId': uid, // Firebase UID để tìm KhachHang
      'Tendathang': hoTen,
      'SoDienThoaidathang': sdt,
      'ShippingAddress': diaChi,
      'Notes': ghiChu,
      'M_PhuongThuc': phuongThucThanhToan, // Bắt buộc phải là mã (PT001...)
      'TongTien': tongTien,
      'NgayDat': now.toIso8601String(),

      // Danh sách chi tiết để lưu vào bảng ChiTietDatHang
      'ChiTietDonHangs': cartItems.map((item) => {
        'M_SanPham': item.productId,
        'TenSanPham': item.title,
        'SoLuong': item.weight, // Map vào cột SoLuong hoặc KhoiLuong tùy DB
        'DonGia': item.price
      }).toList()
    };

    try {
      // --- BƯỚC 1: LƯU FIREBASE ---
      await FirebaseFirestore.instance.collection('DonHang').add(firebaseData);
      print("✅ Đã lưu đơn hàng lên Firebase");

      // --- BƯỚC 2: GỬI SQL SERVER ---
      final url = Uri.parse('$baseUrl/tao-don-hang');
      print("🚀 Đang gửi đơn hàng tới SQL: $url");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sqlData),
      );

      print("📩 Server phản hồi: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Gửi SQL thành công!");
        return true;
      } else {
        print("❌ Lỗi Server SQL: ${response.body}");
        // Có thể bạn muốn xóa đơn trên Firebase nếu SQL lỗi? (Tùy logic)
        return false;
      }
    } catch (e) {
      print("❌ Lỗi kết nối CheckoutService: $e");
      return false;
    }
  }
}