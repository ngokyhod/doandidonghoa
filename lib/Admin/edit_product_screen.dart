import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_api_service.dart';
import '../theme_notifier.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;
  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['tenSanPham']);
    _priceController = TextEditingController(text: widget.product['gia']?.toString());
    _stockController = TextEditingController(text: widget.product['tonKho']?.toString());
    _descController = TextEditingController(text: widget.product['moTa'] ?? 'Thông tin sản phẩm phụ phẩm nông nghiệp chất lượng cao.');
  }

  Future<void> _saveProduct() async {
    setState(() => _isSaving = true);
    // Giả lập gọi API update
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin sản phẩm!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F6F9),
      appBar: AppBar(
        title: Text('Chỉnh sửa Sản phẩm', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 18,
                      child: IconButton(icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white), onPressed: () {}),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildField('Tên sản phẩm', _nameController, isDarkMode),
            _buildField('Giá bán (đ)', _priceController, isDarkMode, keyboardType: TextInputType.number),
            _buildField('Số lượng tồn (kg)', _stockController, isDarkMode, keyboardType: TextInputType.number),
            _buildField('Mô tả sản phẩm', _descController, isDarkMode, maxLines: 4),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('LƯU THAY ĐỔI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, bool isDarkMode, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
            ),
          ),
        ],
      ),
    );
  }
}
