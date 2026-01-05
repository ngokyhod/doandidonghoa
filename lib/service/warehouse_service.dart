import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/inventory_model.dart'; // Import model vừa tạo

class WarehouseService {
  // Thay đổi IP này theo máy tính của bạn (giống các service khác)
  static const String baseUrl = 'https://localhost:7240/api/MobileApi';

  static Future<List<InventoryItem>> fetchInventory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/inventory'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((item) => InventoryItem.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Lỗi Fetch Inventory: $e');
      return [];
    }
  }

}