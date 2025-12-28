import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/product_model.dart';
import '../service/Product_Service.dart';
import '../service/sendThuGomToSql.dart';
import '../vietnam_address_data.dart'; // Đảm bảo bạn đã cập nhật file này theo AddressModel

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

  // --- STATE CHO SẢN PHẨM ---
  List<Product> _allProductsFromApi = [];
  List<String> _categories = [];
  List<Product> _filteredProducts = [];
  String? _selectedCategory;
  Product? _selectedProduct;
  bool _isLoadingProduct = true;
  bool _isSubmitting = false;

  // --- STATE CHO ĐỊA CHỈ (Sử dụng AddressModel thay vì String) ---
  AddressModel? _selectedCityModel;
  AddressModel? _selectedDistrictModel;
  AddressModel? _selectedWardModel;

  // --- STATE ĐỘ ẨM ---
  double _moistureValue = 15.0;

  @override
  void initState() {
    super.initState();
    _loadDataFromApi();
  }

  // Tải API sản phẩm
  void _loadDataFromApi() async {
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
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
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
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        // Chuẩn bị địa chỉ đầy đủ để hiển thị
        String fullAddressStr = "${_addressController.text}, ${_selectedWardModel?.name}, ${_selectedDistrictModel?.name}, ${_selectedCityModel?.name}";

        final requestData = {
          'uid': user.uid,
          'email': user.email ?? "",
          'contactName': _nameController.text.trim(),
          'contactPhone': _phoneController.text.trim(),

          // Lưu cả MÃ (để xử lý) và TÊN (để hiển thị) lên Firebase
          'maTinh': _selectedCityModel?.code ?? "",
          'tenTinh': _selectedCityModel?.name ?? "",
          'maQuan': _selectedDistrictModel?.code ?? "",
          'tenQuan': _selectedDistrictModel?.name ?? "",
          'maXa': _selectedWardModel?.code ?? "",
          'tenXa': _selectedWardModel?.name ?? "",

          'diaChiCuThe': _addressController.text.trim(),
          'fullAddress': fullAddressStr,
          'category': _selectedCategory,
          'productName': _selectedProduct?.title ?? "Chưa chọn",
          'productId': _selectedProduct?.id ?? "",
          'amount': double.tryParse(_weightController.text) ?? 0,
          'giaTriMongMuon': double.tryParse(_priceController.text) ?? 0,
          'moTa': _noteController.text.trim(),
          'doAm': _moistureValue,
          'trangThaiXuLy': 'MoiYeuCau',
          'createdAt': FieldValue.serverTimestamp(),
        };

        // 1. Đẩy lên Collection "ThuGom" (Firebase)
        await FirebaseFirestore.instance.collection('ThuGom').add(requestData);

        // 2. Gửi sang SQL Server (QUAN TRỌNG: Gửi CODE chứ không gửi TÊN)
        bool sqlSuccess = await sendThuGomToSql.sendThuGom(
          uid: user.uid,
          hoTen: _nameController.text,
          sdt: _phoneController.text,
          address: _addressController.text,

          // --- Gửi MÃ (Code) sang SQL để khớp với bảng XaPhuongs ---
          maTinh: _selectedCityModel?.code ?? "",     // VD: T01
          maQuan: _selectedDistrictModel?.code ?? "", // VD: Q0101
          maXa: _selectedWardModel?.code ?? "",       // VD: X010101
          // --------------------------------------------------------

          tenSP: _selectedProduct?.title ?? "",
          loaiSP: _selectedCategory ?? "",
          khoiLuong: double.tryParse(_weightController.text) ?? 0,
          gia: double.tryParse(_priceController.text) ?? 0,
          doAm: _moistureValue,
          ghiChu: _noteController.text,
          hinhAnh: [], // Gửi mảng rỗng để tránh lỗi validate API
        );

        if (mounted) {
          // Thông báo dựa trên kết quả SQL
          if (sqlSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Gửi yêu cầu thành công!"), backgroundColor: Colors.green),
            );
            context.pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ Đã lưu Firebase nhưng lỗi đồng bộ SQL."), backgroundColor: Colors.orange),
            );
            context.pop(); // Vẫn cho thoát vì đã lưu được ở Firebase
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Lỗi: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
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

              // HỌ TÊN
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Họ tên", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Nhập họ tên";
                  if (!RegExp(r"^[a-zA-ZÀ-ỹ\s]+$").hasMatch(val)) return "Tên không chứa số/ký tự lạ";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // SỐ ĐIỆN THOẠI
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

              // DROPDOWN LOẠI SP
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Loại phụ phẩm", border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: _onCategoryChanged,
                validator: (val) => val == null ? "Chọn loại" : null,
              ),
              const SizedBox(height: 12),

              // DROPDOWN SẢN PHẨM CỤ THỂ
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
                  // KHỐI LƯỢNG
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
                      decoration: const InputDecoration(labelText: "Khối lượng (kg)", border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Nhập KL";
                        final n = double.tryParse(val);
                        if (n == null || n <= 0) return "> 0";
                        if (n > 1000) return "Max 1000kg";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // GIÁ MONG MUỐN
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
              // THANH ĐỘ ẨM
              _buildMoistureSlider(),

              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Mô tả thêm (Tình trạng...)", border: OutlineInputBorder(), alignLabelWithHint: true),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle("Địa chỉ thu gom"),

              // CHỌN ĐỊA CHỈ (Đã cập nhật dùng AddressModel)
              _buildAddressSelectors(),

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

  // Widget Thanh Độ Ẩm
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

  // Widget Dropdown Địa chỉ (Sửa logic lấy Mã và load động)
  Widget _buildAddressSelectors() {
    return Column(
      children: [
        // 1. Tỉnh / TP
        DropdownButtonFormField<AddressModel>(
          value: _selectedCityModel,
          decoration: const InputDecoration(labelText: "Tỉnh / Thành phố", border: OutlineInputBorder()),
          // Lấy list provinces từ file dữ liệu mới
          items: VietnamAddressData.provinces.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCityModel = val;
              _selectedDistrictModel = null;
              _selectedWardModel = null;
            });
          },
          validator: (val) => val == null ? "Chọn Tỉnh/TP" : null,
        ),
        const SizedBox(height: 12),

        // 2. Quận / Huyện
        DropdownButtonFormField<AddressModel>(
          value: _selectedDistrictModel,
          decoration: const InputDecoration(labelText: "Quận / Huyện", border: OutlineInputBorder()),
          // Lấy list quận dựa theo CODE của Tỉnh
          items: (_selectedCityModel == null
              ? <AddressModel>[]
              : VietnamAddressData.districts[_selectedCityModel!.code] ?? [])
              .map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
          onChanged: _selectedCityModel == null ? null : (val) {
            setState(() {
              _selectedDistrictModel = val;
              _selectedWardModel = null;
            });
          },
          validator: (val) => val == null ? "Chọn Quận/Huyện" : null,
        ),
        const SizedBox(height: 12),

        // 3. Phường / Xã
        DropdownButtonFormField<AddressModel>(
          value: _selectedWardModel,
          decoration: const InputDecoration(labelText: "Phường / Xã", border: OutlineInputBorder()),
          // Lấy list phường dựa theo CODE của Quận
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