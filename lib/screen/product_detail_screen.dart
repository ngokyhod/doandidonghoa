import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../model/product_model.dart';
import '../service/Product_Service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Product? extraProduct; // Dữ liệu truyền nhanh từ màn hình trước

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.extraProduct,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product?> _productDetailFuture;

  // --- SỬA LỖI: THÊM DÒNG KHAI BÁO NÀY ---
  late Future<List<Product>> _relatedProductsFuture;
  // ----------------------------------------

  int _quantity = 1;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _productDetailFuture = ProductService.fetchProductDetail(widget.productId);

    // Khởi tạo giá trị mặc định (rỗng) để tránh lỗi LateInitializationError
    _relatedProductsFuture = Future.value([]);
  }

  // Hàm tăng giảm số lượng
  void _updateQuantity(int change, int maxStock) {
    setState(() {
      int newQuantity = _quantity + change;
      if (newQuantity >= 1 && newQuantity <= maxStock) {
        _quantity = newQuantity;
      }
    });
  }

  void _addToCart(Product product) {
    // TODO: Gọi CartService để thêm vào giỏ hàng
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã thêm $_quantity ${product.unit} ${product.title} vào giỏ!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar trong suốt để ảnh tràn lên trên
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
              onPressed: () => context.push('/cart'),
            ),
          )
        ],
      ),
      body: FutureBuilder<Product?>(
        future: _productDetailFuture,
        initialData: widget.extraProduct, // Hiển thị dữ liệu cũ trước khi tải xong chi tiết
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
            return const Center(child: Text("Không tìm thấy sản phẩm"));
          }

          final product = snapshot.data!;

          // Khi đã tải xong chi tiết sản phẩm, ta mới có Category để tải sản phẩm liên quan
          if (snapshot.connectionState == ConnectionState.done) {
            // Lưu ý: Đặt logic này ở đây có thể khiến build lại nhiều lần,
            // nhưng tạm thời chấp nhận được. Tốt hơn là dùng Future.wait ở initState.
            _relatedProductsFuture = ProductService.fetchRelatedProducts(product.category, product.id);
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Ảnh sản phẩm
                      _buildProductImage(product),

                      // 2. Thông tin chính
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Giá và Trạng thái
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _currencyFormat.format(product.price),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: product.stockQuantity > 0 ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.stockQuantity > 0 ? "Còn hàng" : "Hết hàng",
                                    style: TextStyle(
                                        color: product.stockQuantity > 0 ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(product.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text("Mã SP: ${product.id} | ĐVT: ${product.unit}", style: TextStyle(color: Colors.grey[600])),

                            // Chọn số lượng
                            const SizedBox(height: 20),
                            const Divider(),
                            if (product.stockQuantity > 0)
                              _buildQuantitySelector(product.stockQuantity),

                            // Mô tả
                            const SizedBox(height: 20),
                            const Divider(),
                            const Text("Mô tả sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                                product.description.isEmpty ? "Đang cập nhật..." : product.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                                style: TextStyle(color: Colors.grey[800], height: 1.5)
                            ),

                            // Đánh giá
                            const SizedBox(height: 20),
                            const Divider(),
                            _buildReviewSection(product),

                            const SizedBox(height: 30),
                            const Divider(thickness: 4, color: Color(0xFFF5F5F5)),
                            const SizedBox(height: 20),

                            // --- SẢN PHẨM LIÊN QUAN ---
                            const Text("Sản phẩm bạn có thể thích", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _buildRelatedProductsList(),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(product),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRelatedProductsList() {
    return FutureBuilder<List<Product>>(
      future: _relatedProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }

        // Sửa logic check null/empty cho an toàn hơn
        if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Không có sản phẩm tương tự.", style: TextStyle(color: Colors.grey)),
          );
        }

        final related = snapshot.data!;

        return SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (ctx, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = related[index];
              return GestureDetector(
                onTap: () {
                  context.push('/product/${item.id}', extra: item);
                },
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: item.imageUrls.isNotEmpty
                              ? Image.network(item.imageUrls.first, fit: BoxFit.cover, width: double.infinity)
                              : Container(color: Colors.grey[100], child: const Icon(Icons.image, color: Colors.grey)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(item.price),
                              style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      height: 350,
      width: double.infinity,
      color: Colors.grey[100],
      child: product.imageUrls.isNotEmpty
          ? Image.network(product.imageUrls.first, fit: BoxFit.contain)
          : const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
    );
  }

  Widget _buildQuantitySelector(int maxStock) {
    return Row(
      children: [
        const Text("Số lượng:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _quantity > 1 ? () => _updateQuantity(-1, maxStock) : null,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text("$_quantity", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _quantity < maxStock ? () => _updateQuantity(1, maxStock) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Đánh giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: const Text("Xem tất cả")),
          ],
        ),
        if (product.reviews.isEmpty)
          const Text("Chưa có đánh giá nào.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: product.reviews.length > 3 ? 3 : product.reviews.length,
            itemBuilder: (context, index) {
              final review = product.reviews[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                title: Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: List.generate(5, (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        size: 14, color: Colors.orange
                    ))),
                    const SizedBox(height: 4),
                    Text(review.comment),
                  ],
                ),
                trailing: Text(DateFormat('dd/MM/yyyy').format(review.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              );
            },
          )
      ],
    );
  }

  Widget _buildBottomAction(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.red),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: product.stockQuantity > 0 ? () => _addToCart(product) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  product.stockQuantity > 0 ? "Thêm vào giỏ - ${_currencyFormat.format(product.price * _quantity)}" : "Hết hàng",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}