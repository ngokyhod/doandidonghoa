class AddressModel {
  final String name;
  final String code;
  AddressModel({required this.name, required this.code});
}

class VietnamAddressData {
  // 1. DỮ LIỆU TỈNH / THÀNH PHỐ (Khớp với quy tắc mã của bạn: Hà Nội T01, HCM T02...)
  static final List<AddressModel> provinces = [
    AddressModel(name: 'Hà Nội', code: 'T01'),
    AddressModel(name: 'TP. Hồ Chí Minh', code: 'T02'),
    AddressModel(name: 'Đà Nẵng', code: 'T03'),
    AddressModel(name: 'Bình Dương', code: 'T04'),
    AddressModel(name: 'Cần Thơ', code: 'T05'),
  ];

  // 2. DỮ LIỆU QUẬN / HUYỆN (Key là Mã Tỉnh)
  static final Map<String, List<AddressModel>> districts = {
    'T01': [ // Hà Nội
      AddressModel(name: 'Quận Hoàn Kiếm', code: 'Q0101'),
      AddressModel(name: 'Quận Ba Đình', code: 'Q0102'),
      AddressModel(name: 'Quận Đống Đa', code: 'Q0103'),
      AddressModel(name: 'Quận Hai Bà Trưng', code: 'Q0104'),
      AddressModel(name: 'Quận Cầu Giấy', code: 'Q0105'),
    ],
    'T02': [ // TP. HCM
      AddressModel(name: 'Quận 1', code: 'Q0201'),
      AddressModel(name: 'Quận 3', code: 'Q0202'),
      AddressModel(name: 'Quận Bình Thạnh', code: 'Q0203'),
      AddressModel(name: 'Quận Tân Bình', code: 'Q0204'),
      AddressModel(name: 'TP Thủ Đức', code: 'Q0205'),
    ],
    'T03': [ // Đà Nẵng
      AddressModel(name: 'Quận Hải Châu', code: 'Q0301'),
      AddressModel(name: 'Quận Thanh Khê', code: 'Q0302'),
      AddressModel(name: 'Quận Sơn Trà', code: 'Q0303'),
      AddressModel(name: 'Quận Ngũ Hành Sơn', code: 'Q0304'),
      AddressModel(name: 'Quận Liên Chiểu', code: 'Q0305'),
    ],
    'T04': [ // Bình Dương
      AddressModel(name: 'TP Thủ Dầu Một', code: 'Q0401'),
      AddressModel(name: 'TP Dĩ An', code: 'Q0402'),
      AddressModel(name: 'TP Thuận An', code: 'Q0403'),
      AddressModel(name: 'TP Bến Cát', code: 'Q0404'),
      AddressModel(name: 'Huyện Bắc Tân Uyên', code: 'Q0405'),
    ],
    'T05': [ // Cần Thơ
      AddressModel(name: 'Quận Ninh Kiều', code: 'Q0501'),
      AddressModel(name: 'Quận Bình Thuỷ', code: 'Q0502'),
      AddressModel(name: 'Quận Cái Răng', code: 'Q0503'),
      AddressModel(name: 'Quận Ô Môn', code: 'Q0504'),
      AddressModel(name: 'Huyện Phong Điền', code: 'Q0505'),
    ],
  };

  // 3. DỮ LIỆU PHƯỜNG / XÃ (Key là Mã Quận)
  static final Map<String, List<AddressModel>> wards = {
    // --- HÀ NỘI ---
    'Q0101': [ // Hoàn Kiếm
      AddressModel(name: 'Phường Hàng Trống', code: 'X010101'),
      AddressModel(name: 'Phường Lý Thái Tổ', code: 'X010102'),
      AddressModel(name: 'Phường Trần Hưng Đạo', code: 'X010103'),
      AddressModel(name: 'Phường Tràng Tiền', code: 'X010104'),
      AddressModel(name: 'Phường Hàng Buồm', code: 'X010105'),
    ],
    'Q0102': [ // Ba Đình
      AddressModel(name: 'Phường Phúc Xá', code: 'X010201'),
      AddressModel(name: 'Phường Trúc Bạch', code: 'X010202'),
      AddressModel(name: 'Phường Vĩnh Phúc', code: 'X010203'),
      AddressModel(name: 'Phường Cống Vị', code: 'X010204'),
      AddressModel(name: 'Phường Liễu Giai', code: 'X010205'),
    ],
    'Q0103': [ // Đống Đa
      AddressModel(name: 'Phường Cát Linh', code: 'X010301'),
      AddressModel(name: 'Phường Hàng Bột', code: 'X010302'),
      AddressModel(name: 'Phường Láng Hạ', code: 'X010303'),
      AddressModel(name: 'Phường Láng Thượng', code: 'X010304'),
      AddressModel(name: 'Phường Khâm Thiên', code: 'X010305'),
    ],
    'Q0104': [ // Hai Bà Trưng
      AddressModel(name: 'Phường Nguyễn Du', code: 'X010401'),
      AddressModel(name: 'Phường Lê Đại Hành', code: 'X010402'),
      AddressModel(name: 'Phường Bùi Thị Xuân', code: 'X010403'),
      AddressModel(name: 'Phường Phố Huế', code: 'X010404'),
      AddressModel(name: 'Phường Đồng Nhân', code: 'X010405'),
    ],
    'Q0105': [ // Cầu Giấy
      AddressModel(name: 'Phường Nghĩa Đô', code: 'X010501'),
      AddressModel(name: 'Phường Nghĩa Tân', code: 'X010502'),
      AddressModel(name: 'Phường Mai Dịch', code: 'X010503'),
      AddressModel(name: 'Phường Dịch Vọng', code: 'X010504'),
      AddressModel(name: 'Phường Yên Hoà', code: 'X010505'),
    ],

    // --- TP. HCM ---
    'Q0201': [ // Quận 1
      AddressModel(name: 'Phường Tân Định', code: 'X020101'),
      AddressModel(name: 'Phường Đa Kao', code: 'X020102'),
      AddressModel(name: 'Phường Bến Nghé', code: 'X020103'),
      AddressModel(name: 'Phường Bến Thành', code: 'X020104'),
      AddressModel(name: 'Phường Nguyễn Thái Bình', code: 'X020105'),
    ],
    'Q0202': [ // Quận 3
      AddressModel(name: 'Võ Thị Sáu', code: 'X020201'),
      AddressModel(name: 'Phường 1', code: 'X020202'),
      AddressModel(name: 'Phường 2', code: 'X020203'),
      AddressModel(name: 'Phường 4', code: 'X020204'),
      AddressModel(name: 'Phường 9', code: 'X020205'),
    ],
    'Q0203': [ // Bình Thạnh
      AddressModel(name: 'Phường 1', code: 'X020301'),
      AddressModel(name: 'Phường 2', code: 'X020302'),
      AddressModel(name: 'Phường 3', code: 'X020303'),
      AddressModel(name: 'Phường 5', code: 'X020304'),
      AddressModel(name: 'Phường 6', code: 'X020305'),
    ],
    'Q0204': [ // Tân Bình
      AddressModel(name: 'Phường 1', code: 'X020401'),
      AddressModel(name: 'Phường 2', code: 'X020402'),
      AddressModel(name: 'Phường 3', code: 'X020403'),
      AddressModel(name: 'Phường 4', code: 'X020404'),
      AddressModel(name: 'Phường 5', code: 'X020405'),
    ],
    'Q0205': [ // Thủ Đức
      AddressModel(name: 'Phường An Khánh', code: 'X020501'),
      AddressModel(name: 'Phường An Lợi Đông', code: 'X020502'),
      AddressModel(name: 'Phường An Phú', code: 'X020503'),
      AddressModel(name: 'Phường Bình Chiểu', code: 'X020504'),
      AddressModel(name: 'Phường Bình Thọ', code: 'X020505'),
    ],

    // --- Cần thêm dữ liệu cho Đà Nẵng, Bình Dương, Cần Thơ tương tự như trên ---
    // (Tôi đã rút gọn để ví dụ, bạn copy tiếp các dòng insert SQL vào đây theo mẫu trên)
  };
}