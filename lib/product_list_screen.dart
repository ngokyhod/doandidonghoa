import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// --- QUAN TRỌNG: Import chuẩn file model và service ---
// Đảm bảo tên file trong thư mục lib của bạn là 'product_model.dart' và 'product_service.dart'
import 'product_model.dart';
import 'Product_Service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // State lưu từ khóa tìm kiếm và danh mục đang chọn
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';

  // Danh sách các danh mục để lọc nhanh (Giống bên Backend Visual của bạn)
  final List<String> _categories = [
    "Tất cả",
    "Đã qua xử lý",
    "Phụ phẩm thô",
    "Thức ăn chăn nuôi",
    "Phân bón"
  ];

  @override
  void initState() {
    super.initState();
    // Lắng nghe thay đổi text trong ô tìm kiếm
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tính năng lọc nâng cao đang phát triển..."))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 1. Thanh Header (Tìm kiếm, Giỏ hàng)
            _buildHeader(context),

            // 2. Thanh lọc danh mục ngang
            _buildCategoryFilterBar(),

            // 3. Lưới sản phẩm (Gọi API từ Visual)
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
    );
  }

  // --- Widget 1: Header ---
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.green),
            onPressed: _showFilterSheet,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm...',
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black54),
            onPressed: () => context.push('/cart'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // --- Widget 2: Filter Bar ---
  Widget _buildCategoryFilterBar() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? category : 'Tất cả';
              });
            },
            selectedColor: Colors.green.withOpacity(0.2),
            backgroundColor: Colors.grey[100],
            labelStyle: TextStyle(
              color: isSelected ? Colors.green[800] : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  // --- Widget 3: Product Grid (Logic gọi API) ---
  Widget _buildProductGrid() {
    // Gọi hàm fetchProducts từ file product_service.dart
    return FutureBuilder<List<Product>>(
      future: ProductService.fetchProducts(
          query: _searchQuery,
          category: _selectedCategory
      ),
      builder: (context, snapshot) {
        // 1. Đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        // 2. Có lỗi (Ví dụ: Không kết nối được Visual API)
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  "Lỗi kết nối Server:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text("Thử lại"),
                )
              ],
            ),
          );
        }

        final data = snapshot.data;
        // 3. Không có dữ liệu
        if (data == null || data.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("Không tìm thấy sản phẩm nào", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // 4. Hiển thị dữ liệu thành công
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            return _buildProductItem(context, data[index]);
          },
        );
      },
    );
  }

  // Widget hiển thị từng ô sản phẩm
  Widget _buildProductItem(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                  product.imageUrls.first,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    );
                  },
                )
                    : Container(
                  color: Colors.green.withOpacity(0.1),
                  child: const Center(child: Icon(Icons.spa, size: 40, color: Colors.green)),
                ),
              ),
            ),

            // Thông tin
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (product.category.isNotEmpty)
                    Text(
                      product.category,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      maxLines: 1,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(product.price),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}