import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để dùng InputFormatter
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../vietnam_address_data.dart'; // Import file dữ liệu địa chỉ

class CreateScrapCollectionRequestScreen extends StatefulWidget {
  const CreateScrapCollectionRequestScreen({super.key});

  @override
  State<CreateScrapCollectionRequestScreen> createState() => _CreateScrapCollectionRequestScreenState();
}

class _CreateScrapCollectionRequestScreenState extends State<CreateScrapCollectionRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  // Biến lưu địa chỉ được chọn
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedWard;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- HÀM XỬ LÝ KHI BẤM GỬI ---
  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {

      // Kiểm tra Đăng nhập
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Yêu cầu đăng nhập"),
            content: const Text("Bạn cần đăng nhập để gửi yêu cầu thu gom."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/login');
                },
                child: const Text("Đăng nhập ngay"),
              ),
            ],
          ),
        );
        return;
      }

      // Xử lý gửi
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gửi yêu cầu thành công! Đang chờ xử lý..."), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký thu gom"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Thông tin người bán",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 12),

                // --- 1. HỌ TÊN ---
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Họ và tên",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Vui lòng nhập họ tên";
                    final nameRegExp = RegExp(r"^[a-zA-ZÀ-ỹ\s]+$");
                    if (!nameRegExp.hasMatch(value)) {
                      return "Tên không được chứa số hoặc ký tự đặc biệt";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // --- 2. SỐ ĐIỆN THOẠI ---
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: "Số điện thoại",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    counterText: "",
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Vui lòng nhập SĐT";
                    if (value.length != 10 || !value.startsWith('0')) {
                      return "SĐT phải có 10 chữ số và bắt đầu bằng số 0";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                const Text(
                  "Thông tin phụ phẩm",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 12),

                // --- 3. TÊN PHỤ PHẨM ---
                TextFormField(
                  controller: _productNameController,
                  decoration: const InputDecoration(
                    labelText: "Tên phụ phẩm (VD: Rơm, Vỏ trấu)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.grass),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Vui lòng nhập tên phụ phẩm" : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    // --- 4. KHỐI LƯỢNG ---
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Khối lượng (kg)",
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Nhập KL";
                          final n = double.tryParse(value);
                          if (n == null || n <= 0) return "Phải > 0";
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // --- 5. GIÁ MONG MUỐN ---
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Giá (VNĐ)",
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Nhập giá";
                          final n = double.tryParse(value);
                          if (n == null || n <= 0) return "Phải > 0";
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // --- MÔ TẢ ---
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Mô tả chi tiết (Tình trạng, độ ẩm...)",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  "Địa chỉ thu gom",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 12),

                // --- CHỌN ĐỊA CHỈ ---
                _buildAddressSelectors(),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: "Số nhà, tên đường",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Vui lòng nhập địa chỉ cụ thể" : null,
                ),

                const SizedBox(height: 32),

                // --- NÚT GỬI ---
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "GỬI YÊU CẦU",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget chọn địa chỉ dùng VietnamAddressData
  Widget _buildAddressSelectors() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: const InputDecoration(labelText: "Tỉnh / Thành phố", border: OutlineInputBorder()),
          items: VietnamAddressData.cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCity = val;
              _selectedDistrict = null;
              _selectedWard = null;
            });
          },
          validator: (val) => val == null ? "Chọn Tỉnh/TP" : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedDistrict,
          decoration: const InputDecoration(labelText: "Quận / Huyện", border: OutlineInputBorder()),
          // SỬA LỖI Ở ĐÂY: Thêm <String>[] để Dart hiểu đúng kiểu dữ liệu
          items: (_selectedCity == null ? <String>[] : VietnamAddressData.districts[_selectedCity] ?? <String>[])
              .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: _selectedCity == null ? null : (val) {
            setState(() {
              _selectedDistrict = val;
              _selectedWard = null;
            });
          },
          validator: (val) => val == null ? "Chọn Quận/Huyện" : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedWard,
          decoration: const InputDecoration(labelText: "Phường / Xã", border: OutlineInputBorder()),
          // SỬA LỖI Ở ĐÂY TƯƠNG TỰ
          items: (_selectedDistrict == null ? <String>[] : VietnamAddressData.wards[_selectedDistrict] ?? <String>[])
              .map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
          onChanged: _selectedDistrict == null ? null : (val) => setState(() => _selectedWard = val),
          validator: (val) => val == null ? "Chọn Phường/Xã" : null,
        ),
      ],
    );
  }
}