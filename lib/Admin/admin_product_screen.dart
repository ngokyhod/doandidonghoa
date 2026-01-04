import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/product_model.dart';
import '../service/Product_Service.dart';
// import 'edit_product_screen.dart'; // Import màn hình sửa nếu có

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

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
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
    }
  }

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

  // --- LOGIC XÓA SẢN PHẨM ---
  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa '${product.title}'?\n\nHành động này yêu cầu kết nối Server."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng popup trước

              // Gọi Service Xóa
              _showLoading(true);
              bool success = await ProductService.deleteProduct(product.id);
              _showLoading(false);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã xóa thành công!")));
                _loadProducts(); // Tải lại danh sách
              } else {
                _showErrorDialog("Không thể xóa sản phẩm. \nNguyên nhân: Server Visual Studio đang tắt hoặc lỗi mạng.");
              }
            },
            child: const Text("Xóa ngay"),
          ),
        ],
      ),
    );
  }

  // --- LOGIC SỬA SẢN PHẨM ---
  void _onEditPressed(Product product) {
    // Chuyển sang màn hình sửa (Bạn tự tạo màn hình này và gọi ProductService.updateProduct khi Save)
    // Ví dụ:
    // Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductScreen(product: product)));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tính năng Sửa đang phát triển (Yêu cầu Server Online)")),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Lỗi kết nối"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 50, color: Colors.red),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))],
      ),
    );
  }

  void _showLoading(bool show) {
    if (show) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    } else {
      // Chỉ đóng nếu đang có dialog (hacky check)
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true, fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? const Center(child: Text("Không tìm thấy sản phẩm"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) => _buildProductItem(_filteredProducts[index]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrls.isNotEmpty
                  ? Image.network(product.imageUrls.first, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[200], width: 70, height: 70))
                  : Container(color: Colors.grey[200], width: 70, height: 70, child: const Icon(Icons.image)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("Giá: ${formatCurrency.format(product.price)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
            // --- NÚT SỬA ---
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _onEditPressed(product),
            ),
            // --- NÚT XÓA ---
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(product), // Gọi hàm xác nhận xóa
            ),
          ],
        ),
      ),
    );
  }
}