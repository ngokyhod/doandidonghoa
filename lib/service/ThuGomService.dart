import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ThuGomService {
  static String get baseUrl {
    if (kIsWeb) return 'https://localhost:7240/api/MobileApi';
    return 'http://10.0.2.2:5056/api/MobileApi';
  }

  static Future<bool> createThuGomRequest({
    required String uid,
    required String hoTen,
    required String sdt,
    required String diaChiCuThe,
    required String maTinh,
    required String maQuan,
    required String maXa,
    required String tenSP,
    required String loaiSP,
    required String productId, // Thêm productId để đồng bộ
    required double khoiLuong,
    required double giaMongMuon,
    required double doAm,
    required String ghiChu,
    List<String>? hinhAnh,
  }) async {
    // 1. CHUẨN BỊ DỮ LIỆU SQL
    final Map<String, dynamic> sqlData = {
      "UserId": uid,
      "HoTen": hoTen,
      "SoDienThoai": sdt,
      "DiaChiCuThe": diaChiCuThe,
      "MaTinh": maTinh, "MaQuan": maQuan, "MaXa": maXa,
      "TenSanPham": tenSP,
      "LoaiSanPham": loaiSP,
      "KhoiLuong": khoiLuong,
      "GiaMongMuon": giaMongMuon,
      "DoAm": doAm,
      "GhiChu": ghiChu,
      "HinhAnh": hinhAnh ?? [],
      "ThoiGianSanSang": DateTime.now().toIso8601String(),
      "IsCongKenh": false, "IsAmUot": false, "IsTapChat": false,
      "DonViTinh": "KG"
    };

    // 2. CHUẨN BỊ DỮ LIỆU FIREBASE (MẶC ĐỊNH LÀ CHƯA SYNC)
    final Map<String, dynamic> firebaseData = {
      'uid': uid,
      'contactName': hoTen,
      'contactPhone': sdt,
      'maTinh': maTinh, 'maQuan': maQuan, 'maXa': maXa,
      'diaChiCuThe': diaChiCuThe,
      'productName': tenSP,
      'category': loaiSP,
      'productId': productId,
      'amount': khoiLuong,
      'giaTriMongMuon': giaMongMuon,
      'doAm': doAm,
      'moTa': ghiChu,
      'trangThaiXuLy': 'ChoDongBo',
      'createdAt': FieldValue.serverTimestamp(),

      // CỜ QUAN TRỌNG
      'isSync': false,
      'sqlPayload': jsonEncode(sqlData)
    };

    try {
      print("🚀 [ThuGom] Đang thử gửi tới SQL...");
      final response = await http.post(
        Uri.parse('$baseUrl/tao-yeu-cau-thu-gom'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sqlData),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // --- NẾU SQL THÀNH CÔNG ---
        firebaseData['isSync'] = true;
        firebaseData['trangThaiXuLy'] = 'MoiYeuCau'; // Trạng thái đã lên SQL
        firebaseData.remove('sqlPayload'); // Xóa payload vì đã sync xong
        print("✅ SQL ThuGom thành công.");
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối SQL: $e. Lưu Firestore ở chế độ Chờ đồng bộ.");
    }

    // 3. LUÔN LƯU VÀO FIREBASE
    try {
      await FirebaseFirestore.instance.collection('ThuGom').add(firebaseData);
      return true;
    } catch (e) {
      print("🔥 Lỗi lưu Firestore: $e");
      return false;
    }
  }
}