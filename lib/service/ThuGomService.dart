import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ThuGomService {
  // 1. Cấu hình địa chỉ API (Giống ProductService)
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://localhost:7240/api/MobileApi'; // Nếu chạy Web
    } else {
      // Chạy máy ảo Android: 10.0.2.2
      // Chạy máy thật: Đổi thành IP LAN (vd: 192.168.1.x)
      return 'http://10.0.2.2:5056/api/MobileApi';
    }
  }

  // 2. Hàm gửi yêu cầu thu gom sang SQL Server
  static Future<bool> createThuGomRequest({
    required String uid,
    required String hoTen,
    required String sdt,
    required String diaChiCuThe,
    // Các mã địa chỉ (T01, Q001...)
    required String maTinh,
    required String maQuan,
    required String maXa,

    // Thông tin hàng
    required String tenSP,
    required String loaiSP,
    required double khoiLuong,
    required double giaMongMuon,
    required double doAm,
    required String ghiChu,

    // Các tham số mở rộng (để tránh lỗi validate bên Server)
    List<String>? hinhAnh,
    DateTime? thoiGianSanSang,
  }) async {
    final url = Uri.parse('$baseUrl/tao-yeu-cau-thu-gom');

    try {
      print("🚀 Đang gửi API tới: $url");

      final bodyData = {
        // Map đúng key với ThuGomRequestDto bên C#
        "UserId": uid,
        "HoTen": hoTen,
        "SoDienThoai": sdt,
        "DiaChiCuThe": diaChiCuThe,

        "MaTinh": maTinh,
        "MaQuan": maQuan,
        "MaXa": maXa,

        "TenSanPham": tenSP,
        "LoaiSanPham": loaiSP,
        "KhoiLuong": khoiLuong,
        "GiaMongMuon": giaMongMuon,
        "DoAm": doAm,
        "GhiChu": ghiChu,

        // Các trường bổ sung bắt buộc theo logic backend mới
        "HinhAnh": hinhAnh ?? [], // Gửi mảng rỗng nếu không có ảnh
        "ThoiGianSanSang": (thoiGianSanSang ?? DateTime.now()).toIso8601String(),

        // Giá trị mặc định
        "IsCongKenh": false,
        "IsAmUot": false,
        "IsTapChat": false,
        "DonViTinh": "KG"
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        print("✅ Gửi SQL thành công!");
        return true;
      } else {
        print("❌ Lỗi Server SQL (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Lỗi kết nối ThuGomService: $e");
      return false;
    }
  }
}