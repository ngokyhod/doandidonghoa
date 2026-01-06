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
    // ❌ BỎ tham số mYeuCau ở đây đi
    required String uid,
    required String hoTen,
    required String sdt,
    required String diaChiCuThe,
    required String maTinh,
    required String maQuan,
    required String maXa,
    required String tenSP,
    required String loaiSP,
    required String productId,
    required double khoiLuong,
    required double giaMongMuon,
    required double doAm,
    required String ghiChu,
    List<String>? hinhAnh,
  }) async {

    // 1. CHUẨN BỊ DỮ LIỆU GỬI SQL (Không gửi M_YeuCau, để SQL tự tạo)
    final Map<String, dynamic> sqlData = {
      // "M_YeuCau": ..., // <-- KHÔNG GỬI CÁI NÀY
      "UserId": uid,
      "HoTen": hoTen,
      "SoDienThoai": sdt,
      "DiaChiCuThe": diaChiCuThe,
      "MaTinh": maTinh, "MaQuan": maQuan, "MaXa": maXa,
      "TenSanPham": tenSP,
      "LoaiSanPham": loaiSP,
      "ProductId": productId,
      "KhoiLuong": khoiLuong,
      "GiaMongMuon": giaMongMuon,
      "DoAm": doAm,
      "GhiChu": ghiChu,
      "HinhAnh": hinhAnh ?? [],
      "ThoiGianSanSang": DateTime.now().toIso8601String(),
      "IsCongKenh": false, "IsAmUot": false, "IsTapChat": false,
      "DonViTinh": "KG"
    };

    // Chuẩn bị sẵn Map cho Firebase
    final Map<String, dynamic> firebaseData = {
      'm_YeuCau': '', // Tạm thời để trống, chờ Server trả về
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
      'isSync': false,
      'sqlPayload': jsonEncode(sqlData)
    };

    try {
      print("🚀 [ThuGom] Đang gửi lên SQL để lấy mã...");
      final response = await http.post(
        Uri.parse('$baseUrl/tao-yeu-cau-thu-gom'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sqlData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // ✅ THÀNH CÔNG: Server sẽ trả về object chứa mã
        // Giả sử server trả về JSON: { "m_YeuCau": "REQ_12345", "status": "success" ... }
        final responseBody = jsonDecode(response.body);

        // LẤY MÃ TỪ SERVER TRẢ VỀ
        // Bạn cần check xem API C# trả về key tên là gì (ví dụ: 'id', 'm_YeuCau', 'data'...)
        String serverId = responseBody['m_YeuCau'] ?? responseBody['id'] ?? responseBody['maYeuCau'] ?? '';

        if (serverId.isNotEmpty) {
          firebaseData['m_YeuCau'] = serverId; // Cập nhật mã thật vào đây
          firebaseData['isSync'] = true;       // Đã đồng bộ
          firebaseData['trangThaiXuLy'] = 'MoiYeuCau';
          firebaseData.remove('sqlPayload');   // Xóa payload thừa
          print("✅ Đã nhận mã từ Server: $serverId");
        }
      } else {
        print("⚠️ Server trả lỗi: ${response.body}");
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối SQL: $e. Sẽ lưu tạm không có mã.");
    }

    // 2. LƯU VÀO FIREBASE (Có mã nếu API thành công, hoặc rỗng nếu thất bại)
    try {
      await FirebaseFirestore.instance.collection('ThuGom').add(firebaseData);
      return true;
    } catch (e) {
      print("🔥 Lỗi lưu Firestore: $e");
      return false;
    }
  }
}