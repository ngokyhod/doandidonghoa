// File: lib/vietnam_address_data.dart

class VietnamAddressData {
  // Dữ liệu mẫu: Tỉnh/TP -> { Quận/Huyện -> [Phường/Xã] }
  static const Map<String, Map<String, List<String>>> _data = {
    'Hà Nội': {
      'Ba Đình': ['Phúc Xá', 'Trúc Bạch', 'Vĩnh Phúc', 'Cống Vị', 'Liễu Giai'],
      'Hoàn Kiếm': ['Chương Dương', 'Cửa Đông', 'Hàng Bạc', 'Hàng Bồ', 'Hàng Bông'],
      'Hai Bà Trưng': ['Bách Khoa', 'Bạch Đằng', 'Lê Đại Hành', 'Minh Khai'],
    },
    'Hồ Chí Minh': {
      'Quận 1': ['Bến Nghé', 'Bến Thành', 'Cầu Ông Lãnh', 'Cô Giang', 'Đa Kao'],
      'Quận 3': ['Phường 1', 'Phường 2', 'Phường 3', 'Phường 4', 'Phường 5'],
      'Thành phố Thủ Đức': ['An Khánh', 'An Lợi Đông', 'Bình Chiểu', 'Hiệp Bình Chánh'],
    },
    'Đà Nẵng': {
      'Hải Châu': ['Bình Hiên', 'Bình Thuận', 'Hải Châu I', 'Hải Châu II'],
      'Sơn Trà': ['An Hải Bắc', 'An Hải Đông', 'An Hải Tây', 'Mân Thái'],
      'Ngũ Hành Sơn': ['Hòa Hải', 'Hòa Quý', 'Khuê Mỹ', 'Mỹ An'],
    },
  };

  // Lấy danh sách Tỉnh/TP
  static List<String> get cities => _data.keys.toList();

  // Lấy danh sách Quận/Huyện theo Tỉnh/TP
  static Map<String, List<String>> get districts {
    return _data.map((key, value) => MapEntry(key, value.keys.toList()));
  }

  // Lấy danh sách Phường/Xã theo Quận/Huyện
  static Map<String, List<String>> get wards {
    final Map<String, List<String>> allWards = {};
    _data.forEach((city, districtsMap) {
      districtsMap.forEach((district, wardsList) {
        allWards[district] = wardsList;
      });
    });
    return allWards;
  }
}