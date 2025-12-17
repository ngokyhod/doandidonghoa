
import 'package:flutter/material.dart';
import 'vietnam_address_data.dart';

class CreateScrapCollectionRequestScreen extends StatefulWidget {
  const CreateScrapCollectionRequestScreen({super.key});

  @override
  State<CreateScrapCollectionRequestScreen> createState() =>
      _CreateScrapCollectionRequestScreenState();
}

class _CreateScrapCollectionRequestScreenState
    extends State<CreateScrapCollectionRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // State for address dropdowns
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedWard;

  List<String> _districts = [];
  List<String> _wards = [];

  void _onCityChanged(String? newValue) {
    if (newValue == null || newValue == _selectedCity) return;
    setState(() {
      _selectedCity = newValue;
      _selectedDistrict = null;
      _selectedWard = null;
      _districts = vietnamAddressData[newValue]?.keys.toList() ?? [];
      _wards = [];
    });
  }

  void _onDistrictChanged(String? newValue) {
     if (newValue == null || newValue == _selectedDistrict) return;
    setState(() {
      _selectedDistrict = newValue;
      _selectedWard = null;
      if (_selectedCity != null) {
        _wards = vietnamAddressData[_selectedCity]?[newValue] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Yêu Cầu Thu Gom'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('NGƯỜI CUNG CẤP'),
              _buildTextField(label: 'Tên người cung cấp *'),
              _buildTextField(label: 'Số điện thoại *', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              const Text('Địa chỉ lấy phụ phẩm *', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildDropdown(value: _selectedCity, items: vietnamAddressData.keys.toList(), onChanged: _onCityChanged, hint: 'Tỉnh/Thành phố'),
              _buildDropdown(value: _selectedDistrict, items: _districts, onChanged: _onDistrictChanged, hint: 'Quận/Huyện'),
              _buildDropdown(value: _selectedWard, items: _wards, onChanged: (val) => setState(() => _selectedWard = val), hint: 'Phường/Xã'),
              _buildTextField(label: 'Địa chỉ chi tiết (Số nhà, đường...)'),
              _buildTextField(label: 'Thời gian sẵn sàng lấy *'), // Consider using a date/time picker
              _buildTextField(label: 'Ghi chú thêm', maxLines: 3),
              const SizedBox(height: 24),
              _buildSectionTitle('THÔNG TIN PHỤ PHẨM'),
              _buildDropdown(label: 'Loại sản phẩm *', items: ['Chọn loại sản phẩm', 'Nhựa', 'Kim loại', 'Giấy']),
              _buildDropdown(label: 'Sản phẩm cụ thể *', items: ['-- Vui lòng chọn loại --']),
              _buildTextField(label: 'Mô tả chi tiết phụ phẩm', maxLines: 3),
              Row(
                children: [
                  Expanded(child: _buildTextField(label: 'Số lượng ước tính')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDropdown(label: 'Đơn vị tính', items: ['Chọn', 'kg', 'tấn'])),
                ],
              ),
              _buildTextField(label: 'Giá trị mong muốn (ước tính)', suffixText: 'VNĐ', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              const Text('Đặc tính phụ phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
              // Checkboxes can be converted to a StatefulWidget for state management
              CheckboxListTile(title: const Text('Cồng kềnh'), value: false, onChanged: (val){}),
              CheckboxListTile(title: const Text('Ẩm/Ướt'), value: false, onChanged: (val){}),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () {}, child: const Text('Gửi Yêu Cầu')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildTextField({required String label, int maxLines = 1, TextInputType? keyboardType, String? suffixText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixText: suffixText),
        validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập $label' : null,
      ),
    );
  }

  Widget _buildDropdown({String? value, required List<String> items, ValueChanged<String?>? onChanged, String? label, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label ?? hint, border: const OutlineInputBorder()),
        validator: (value) => (value == null) ? 'Vui lòng chọn ${label ?? hint}' : null,
        isExpanded: true,
      ),
    );
  }
}
