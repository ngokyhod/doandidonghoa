class InventoryItem {
  final String productName;
  final List<String> imageUrls; // Sửa thành List giống Product
  final double quantity;
  final String unit;
  final String warehouseName;
  final String? expiryDate;

  InventoryItem({
    required this.productName,
    required this.imageUrls,
    required this.quantity,
    required this.unit,
    required this.warehouseName,
    this.expiryDate,
  });

  // Getter này giúp UI cũ vẫn gọi được .productImage mà không bị lỗi
  String get productImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // --- LOGIC XỬ LÝ ẢNH GIỐNG MODEL PRODUCT ---
    List<String> parsedImages = [];

    // 1. Ưu tiên lấy từ 'anhSanPham' (Key SQL thường dùng)
    if (json['anhSanPham'] != null && json['anhSanPham'].toString().isNotEmpty) {
      parsedImages = [json['anhSanPham']];
    }
    // 2. Nếu không có, thử lấy từ 'productImage' (Key API Inventory)
    else if (json['productImage'] != null && json['productImage'].toString().isNotEmpty) {
      parsedImages = [json['productImage']];
    }
    // 3. Cuối cùng thử lấy từ 'imageUrls' (Key Firebase/List)
    else if (json['imageUrls'] != null) {
      parsedImages = List<String>.from(json['imageUrls']);
    }

    return InventoryItem(
      productName: json['productName'] ?? json['tenSanPham'] ?? 'Sản phẩm lỗi',

      // Gán list ảnh đã xử lý
      imageUrls: parsedImages,

      quantity: (json['quantity'] ?? json['totalStock'] ?? 0).toDouble(),
      unit: json['unit'] ?? json['tenDVT'] ?? 'kg',
      warehouseName: json['warehouseName'] ?? json['tenKho'] ?? 'Kho chưa xác định',
      expiryDate: json['expiryDate'],
    );
  }
}