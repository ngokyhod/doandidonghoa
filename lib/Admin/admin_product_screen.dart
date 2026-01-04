import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/product_model.dart';
import '../service/Product_Service.dart'; // Sử dụng Service chuẩn của bạn

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Lấy dữ liệu từ ProductService
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      // Gọi Service đã có (Hỗ trợ cả API và Firebase Fallback)
      final products = await ProductService.fetchProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi tải sản phẩm: $e");
    }
  }

  // Hàm tìm kiếm
  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = _allProducts);
    } else {
      setState(() {
        _filteredProducts = _allProducts.where((p) =>
        p.title.toLowerCase().contains(query.toLowerCase()) ||
            p.id.contains(query)
        ).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      body: Column(
        children: [
          // --- THANH TÌM KIẾM ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // --- DANH SÁCH SẢN PHẨM ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? const Center(child: Text("Không tìm thấy sản phẩm"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductItem(_filteredProducts[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Thêm sản phẩm mới (User tự làm sau)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng Thêm đang phát triển")));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrls.isNotEmpty
                  ? Image.network(
                product.imageUrls.first,
                width: 70, height: 70, fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(color: Colors.grey[200], width: 70, height: 70, child: const Icon(Icons.image)),
              )
                  : Container(color: Colors.grey[200], width: 70, height: 70, child: const Icon(Icons.image)),
            ),
            const SizedBox(width: 16),
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Giá: ${formatCurrency.format(product.price)}",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Kho: ${product.stockQuantity} ${product.unit}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            // Nút hành động (User sẽ thêm logic sau)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}