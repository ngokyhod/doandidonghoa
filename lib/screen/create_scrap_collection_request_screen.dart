import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/product_model.dart';
import '../service/Product_Service.dart';
import '../service/ThuGomService.dart'; // <--- Import Service mới
import '../vietnam_address_data.dart'; // File chứa AddressModel

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
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final _addressController = TextEditingController();

  // --- STATE SẢN PHẨM ---
  List<Product> _allProductsFromApi = [];
  List<String> _categories = [];
  List<Product> _filteredProducts = [];
  String? _selectedCategory;
  Product? _selectedProduct;
  bool _isLoadingProduct = true;
  bool _isSubmitting = false;

  // --- STATE ĐỊA CHỈ (Dùng AddressModel) ---
  AddressModel? _selectedCityModel;
  AddressModel? _selectedDistrictModel;
  AddressModel? _selectedWardModel;

  // --- STATE KHÁC ---
  double _moistureValue = 15.0;

  @override
  void initState() {
    super.initState();
    _loadDataFromApi();
  }

  // Tải danh sách sản phẩm từ API
  void _loadDataFromApi() async {
    // Sử dụng ProductService để lấy dữ liệu thật
    List<Product> products = await ProductService.fetchProducts();
    if (mounted) {
      setState(() {
        _allProductsFromApi = products;
        _categories = products
            .map((p) => p.category)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
        _isLoadingProduct = false;
      });
    }
  }

  void _onCategoryChanged(String? newCategory) {
    if (newCategory == null) return;
    setState(() {
      _selectedCategory = newCategory;
      _selectedProduct = null;
      _filteredProducts = _allProductsFromApi
          .where((p) => p.category == newCategory)
          .toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Gọi Service (KHÔNG TRUYỀN mYeuCau nữa)
      bool success = await ThuGomService.createThuGomRequest(
        // mYeuCau: ...,  <-- BỎ DÒNG NÀY
        uid: user.uid,
        hoTen: _nameController.text.trim(),
        sdt: _phoneController.text.trim(),
        diaChiCuThe: _addressController.text.trim(),
        maTinh: _selectedCityModel?.code ?? "",
        maQuan: _selectedDistrictModel?.code ?? "",
        maXa: _selectedWardModel?.code ?? "",
        tenSP: _selectedProduct?.title ?? "",
        loaiSP: _selectedCategory ?? "",
        productId: _selectedProduct?.id ?? "",
        khoiLuong: double.tryParse(_weightController.text) ?? 0,
        giaMongMuon: double.tryParse(_priceController.text) ?? 0,
        doAm: _moistureValue,
        ghiChu: _noteController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Đã gửi yêu cầu thu gom!"), backgroundColor: Colors.green),
          );
          context.go('/');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Gửi yêu cầu thất bại."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi hệ thống: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yêu cầu đăng nhập"),
        content: const Text("Bạn cần đăng nhập để gửi yêu cầu thu gom."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký thu gom"), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: _isLoadingProduct
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Thông tin người bán"),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Họ tên", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (val) => (val == null || val.trim().isEmpty) ? "Nhập họ tên" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(labelText: "SĐT", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone), counterText: ""),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) => (val != null && val.length == 10 && val.startsWith('0')) ? null : "SĐT không hợp lệ",
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("Thông tin phụ phẩm"),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Loại phụ phẩm", border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: _onCategoryChanged,
                validator: (val) => val == null ? "Chọn loại" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Product>(
                decoration: const InputDecoration(labelText: "Sản phẩm cụ thể", border: OutlineInputBorder(), prefixIcon: Icon(Icons.spa)),
                value: _selectedProduct,
                items: _filteredProducts.map((p) => DropdownMenuItem(value: p, child: Text(p.title))).toList(),
                onChanged: (val) => setState(() => _selectedProduct = val),
                validator: (val) => val == null ? "Chọn sản phẩm" : null,
                disabledHint: const Text("Chọn loại trước"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
                      decoration: const InputDecoration(labelText: "Khối lượng (kg)", border: OutlineInputBorder()),
                      validator: (val) => (val == null || val.isEmpty) ? "Nhập KL" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: "Giá mong muốn (VNĐ)", border: OutlineInputBorder()),
                      validator: (val) => (val == null || val.isEmpty) ? "Nhập giá" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildMoistureSlider(),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Mô tả thêm (Tình trạng...)", border: OutlineInputBorder(), alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("Địa chỉ thu gom"),
              _buildAddressSelectors(), // Widget chọn địa chỉ đã sửa
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Số nhà, tên đường", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                validator: (val) => (val == null || val.isEmpty) ? "Nhập địa chỉ cụ thể" : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("GỬI YÊU CẦU", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- CÁC WIDGET CON (Giữ nguyên logic cũ nhưng đổi tên biến cho gọn) ---
  Widget _buildMoistureSlider() {
    Color color;
    String text;
    IconData icon;
    if (_moistureValue <= 12) {
      color = Colors.orange; text = "Rất khô (Rất tốt)"; icon = Icons.local_fire_department;
    } else if (_moistureValue <= 16) {
      color = Colors.green; text = "Đạt chuẩn"; icon = Icons.check_circle;
    } else if (_moistureValue <= 22) {
      color = Colors.blue; text = "Hơi ẩm"; icon = Icons.cloud;
    } else {
      color = Colors.red; text = "Ướt / Dính mưa"; icon = Icons.water_drop;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Độ ẩm:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${_moistureValue.toStringAsFixed(1)}%", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _moistureValue, min: 5, max: 40, divisions: 70, activeColor: color,
            onChanged: (v) => setState(() => _moistureValue = v),
          ),
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
        ],
      ),
    );
  }

  Widget _buildAddressSelectors() {
    return Column(
      children: [
        DropdownButtonFormField<AddressModel>(
          value: _selectedCityModel,
          decoration: const InputDecoration(labelText: "Tỉnh / Thành phố", border: OutlineInputBorder()),
          items: VietnamAddressData.provinces.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
          onChanged: (val) {
            setState(() { _selectedCityModel = val; _selectedDistrictModel = null; _selectedWardModel = null; });
          },
          validator: (val) => val == null ? "Chọn Tỉnh/TP" : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AddressModel>(
          value: _selectedDistrictModel,
          decoration: const InputDecoration(labelText: "Quận / Huyện", border: OutlineInputBorder()),
          items: (_selectedCityModel == null
              ? <AddressModel>[]
              : VietnamAddressData.districts[_selectedCityModel!.code] ?? [])
              .map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
          onChanged: _selectedCityModel == null ? null : (val) {
            setState(() { _selectedDistrictModel = val; _selectedWardModel = null; });
          },
          validator: (val) => val == null ? "Chọn Quận/Huyện" : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AddressModel>(
          value: _selectedWardModel,
          decoration: const InputDecoration(labelText: "Phường / Xã", border: OutlineInputBorder()),
          items: (_selectedDistrictModel == null
              ? <AddressModel>[]
              : VietnamAddressData.wards[_selectedDistrictModel!.code] ?? [])
              .map((w) => DropdownMenuItem(value: w, child: Text(w.name))).toList(),
          onChanged: _selectedDistrictModel == null ? null : (val) => setState(() => _selectedWardModel = val),
          validator: (val) => val == null ? "Chọn Phường/Xã" : null,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)));
  }
}