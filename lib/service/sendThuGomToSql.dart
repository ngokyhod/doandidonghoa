// Trong class ApiService
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../service/ApiService.dart';

  class sendThuGomToSql {
  static Future<bool> sendThuGom({
  required String uid,
  required String hoTen,
  required String sdt,
  required String address,
  required String maTinh,
  required String maQuan,
  required String maXa,
  required String tenSP,
  required String loaiSP,
  required double khoiLuong,
  required double gia,
  required double doAm,
  required String ghiChu,
  List<String>? hinhAnh, // <--- 1. THÊM THAM SỐ NÀY
  }) async {
  final url = Uri.parse('https://localhost:7240/api/MobileApi/tao-yeu-cau-thu-gom');

  try {
  final response = await http.post(
  url,
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
  "UserId": uid,
  "HoTen": hoTen,
  "SoDienThoai": sdt,
  "DiaChiCuThe": address,
  "MaTinh": maTinh,
  "MaQuan": maQuan,
  "MaXa": maXa,
  "TenSanPham": tenSP,
  "LoaiSanPham": loaiSP,
  "KhoiLuong": khoiLuong,
  "GiaMongMuon": gia,
  "DoAm": doAm,
  "GhiChu": ghiChu,

  // <--- 2. THÊM DÒNG NÀY (Gửi list rỗng nếu không có ảnh)
  "HinhAnh": hinhAnh ?? [],

  // Các giá trị mặc định cho các trường bool (để tránh lỗi nếu API yêu cầu)
  "IsCongKenh": false,
  "IsAmUot": false,
  "IsTapChat": false,
  "DonViTinh": "KG"
  }),
  );

  if (response.statusCode == 200) {
  print("✅ Gửi SQL thành công!");
  return true;
  } else {
  print("❌ Lỗi Server SQL: ${response.body}");
  return false;
  }
  } catch (e) {
  print("❌ Lỗi kết nối: $e");
  return false;
  }
  }
}