import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/product_model.dart';
import '../service/Product_Service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Điền sẵn dữ liệu cũ
    _nameController = TextEditingController(text: widget.product.title);
    // Xử lý giá tiền về string bỏ .0 nếu là số nguyên
    String priceStr = widget.product.price % 1 == 0
        ? widget.product.price.toInt().toString()
        : widget.product.price.toString();
    _priceController = TextEditingController(text: priceStr);
    _descController = TextEditingController(text: widget.product.description);
    _categoryController = TextEditingController(text: widget.product.category);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Tạo object mới từ dữ liệu form
    Product updatedProduct = widget.product.copyWith(
      title: _nameController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0,
      description: _descController.text.trim(),
      category: _categoryController.text.trim(),
    );

    // Gọi Service
    bool success = await ProductService.updateProduct(updatedProduct);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Cập nhật thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Trả về true để màn hình trước reload lại
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Cập nhật thất bại"),
            content: const Text("Không thể kết nối đến máy chủ Visual Studio.\nVui lòng kiểm tra lại kết nối hoặc bật Server."),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sửa sản phẩm"), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Tên sản phẩm", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: "Giá bán (VNĐ)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Nhập giá tiền" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: "Loại sản phẩm (Mã hoặc Tên)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Mô tả", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("LƯU THAY ĐỔI", style: TextStyle(fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}