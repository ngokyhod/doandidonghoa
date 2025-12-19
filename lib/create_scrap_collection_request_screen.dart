
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateScrapCollectionRequestScreen extends StatefulWidget {
  const CreateScrapCollectionRequestScreen({super.key});

  @override
  State<CreateScrapCollectionRequestScreen> createState() =>
      _CreateScrapCollectionRequestScreenState();
}

class _CreateScrapCollectionRequestScreenState
    extends State<CreateScrapCollectionRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers để bạn dễ lấy dữ liệu gọi API
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategory;
  String? _selectedUnit = 'kg';

  final List<String> _categories = [
    "Phân bón",
    "Thức ăn chăn nuôi",
    "Năng lượng sinh khối",
    "Phụ phẩm thô",
    "Đã qua xử lý"
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Đăng ký thu gom', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader('1', 'Thông tin người cung cấp'),
              _buildInfoCard([
                _buildInputField(_nameController, 'Họ và tên *', Icons.person_outline),
                _buildInputField(_phoneController, 'Số điện thoại *', Icons.phone_outlined, keyboardType: TextInputType.phone),
                _buildInputField(_addressController, 'Địa chỉ lấy hàng *', Icons.location_on_outlined),
                _buildInputField(_noteController, 'Ghi chú thêm', Icons.notes, maxLines: 2),
              ]),

              const SizedBox(height: 24),
              _buildStepHeader('2', 'Chi tiết phụ phẩm'),
              _buildInfoCard([
                _buildDropdownField('Loại phụ phẩm *', _categories, _selectedCategory, (val) => setState(() => _selectedCategory = val)),
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildInputField(_quantityController, 'Khối lượng *', Icons.scale_outlined, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdownField('Đơn vị', ['kg', 'tấn', 'bao'], _selectedUnit, (val) => setState(() => _selectedUnit = val))),
                  ],
                ),
                _buildInputField(_priceController, 'Giá mong muốn (ước tính)', Icons.payments_outlined, keyboardType: TextInputType.number, suffixText: 'đ/$_selectedUnit'),
              ]),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text('GỬI YÊU CẦU THU GOM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Logic xử lý API của bạn sẽ ở đây
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang xử lý yêu cầu...'), backgroundColor: Colors.blue),
      );

      // Giả lập gửi thành công
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gửi yêu cầu thu gom thành công!'), backgroundColor: Colors.green),
          );
          context.pop();
        }
      });
    }
  }

  Widget _buildStepHeader(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1, String? suffixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
          suffixText: suffixText,
          filled: true,
          fillColor: const Color(0xFFFDFDFD),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32))),
          labelStyle: const TextStyle(fontSize: 14),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng điền $label' : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFFDFDFD),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32))),
        ),
        validator: (value) => value == null ? 'Vui lòng chọn $label' : null,
      ),
    );
  }
}
