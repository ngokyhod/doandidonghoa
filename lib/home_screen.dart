import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'product_model.dart';
import 'Product_Service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  // Controller cho Banner
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Controller cho Tin tức (Carousel 3 items)
  final PageController _newsController = PageController(viewportFraction: 0.35);

  // Dữ liệu API sản phẩm
  late Future<List<Product>> _featuredProductsFuture;

  final List<String> _bannerImageUrls = [
    'assets/images/Banner/banner1.png',
    'assets/images/Banner/banner2.png',
    'assets/images/Banner/banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    _startBannerAutoPlay();
    _featuredProductsFuture = ProductService.fetchProducts();
  }

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        int nextPageIndex = (_currentBannerIndex + 1) % _bannerImageUrls.length;
        _bannerController.animateToPage(
          nextPageIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _newsController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _checkLoginAndGo(String route) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để sử dụng tính năng này"), backgroundColor: Colors.orange),
      );
      context.push('/login');
    } else {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBE7), // Màu nền xanh cốm nhạt
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildUtilityGrid(),
              const SizedBox(height: 16),
              _buildBannerSection(),
              const SizedBox(height: 24),

              _buildSectionTitle("Phụ phẩm nổi bật", onTap: () => context.push('/products')),
              _buildFeaturedProducts(),

              const SizedBox(height: 24),

              // --- PHẦN 1: QUY TRÌNH GIAO DỊCH (GIAO DIỆN MỚI) ---
              _buildSectionTitle("Quy trình giao dịch"),
              _buildTransactionProcessSection(),

              const SizedBox(height: 24),

              // --- PHẦN 2: TIN TỨC ---
              _buildSectionTitle("Tin tức nông nghiệp"),
              _buildNewsCarouselSection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET CON: HEADER & UTILITIES & BANNER
  // --------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm nông sản...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.green, size: 28),
            onPressed: () => _checkLoginAndGo('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.green, size: 28),
            onPressed: () => _checkLoginAndGo('/cart'),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityGrid() {
    final List<Map<String, dynamic>> utilities = [
      {'icon': Icons.recycling, 'label': 'Thu gom', 'route': '/create_scrap_collection_request', 'color': Colors.green},
      {'icon': Icons.psychology, 'label': 'Chatbot', 'route': '/chatbot', 'color': Colors.blue},
      {'icon': Icons.chat, 'label': 'CSKH', 'route': '/admin_chat', 'color': Colors.orange},
      {'icon': Icons.spa, 'label': 'Phụ phẩm', 'route': '/products', 'color': Colors.purple},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: utilities.map((item) {
          return GestureDetector(
            onTap: () {
              if (item['route'] != null) {
                _checkLoginAndGo(item['route']);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng đang phát triển")));
              }
            },
            child: SizedBox(
              width: 70,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item['icon'], color: item['color'], size: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(item['label'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _bannerImageUrls.length,
            onPageChanged: (index) => setState(() => _currentBannerIndex = index),
            itemBuilder: (_, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[300]),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  _bannerImageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _bannerImageUrls.asMap().entries.map((entry) {
            return Container(
              width: 8.0, height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBannerIndex == entry.key ? Colors.green : Colors.grey.shade400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET CON: QUY TRÌNH GIAO DỊCH (GIAO DIỆN STEPPER HIỆN ĐẠI)
  // --------------------------------------------------------------------------

  Widget _buildTransactionProcessSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepItem(
              context,
              Icons.shopping_cart_checkout,
              "Đặt hàng",
              "1",
              detail: "Khách hàng lựa chọn nông sản, thêm vào giỏ hàng và nhập thông tin địa chỉ nhận hàng.",
              isLast: false
          ),
          _buildStepItem(
              context,
              Icons.verified_user_outlined,
              "Xác nhận",
              "2",
              detail: "Người bán hoặc hệ thống xác nhận đơn hàng. Kiểm tra số lượng tồn kho và chốt đơn.",
              isLast: false
          ),
          _buildStepItem(
              context,
              Icons.local_shipping_outlined,
              "Vận chuyển",
              "3",
              detail: "Đơn vị vận chuyển đến lấy hàng từ nông trại và giao tận tay đến địa chỉ của bạn.",
              isLast: false
          ),
          _buildStepItem(
              context,
              Icons.star_outline,
              "Đánh giá",
              "4",
              detail: "Bạn nhận hàng, kiểm tra chất lượng và đánh giá sao/bình luận cho người bán.",
              isLast: true
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, IconData icon, String title, String step, {required String detail, required bool isLast}) {
    return Expanded(
      child: GestureDetector(
        // Sự kiện khi nhấn vào bước
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: Text(step, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Text("Bước $step: $title", style: const TextStyle(fontSize: 18)),
                ],
              ),
              content: Text(detail, style: const TextStyle(fontSize: 15, height: 1.4)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Đóng", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        },
        child: Column(
          children: [
            // Icon với đường nối
            Row(
              children: [
                Expanded(child: Container(height: 2, color: step == "1" ? Colors.transparent : Colors.grey.shade200)), // Đường trái
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.withOpacity(0.5), width: 1.5),
                  ),
                  child: Icon(icon, size: 20, color: Colors.green),
                ),
                Expanded(child: Container(height: 2, color: isLast ? Colors.transparent : Colors.grey.shade200)), // Đường phải
              ],
            ),
            const SizedBox(height: 8),

            // Tiêu đề
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),

            // Nút "Xem" nhỏ bên dưới để gợi ý bấm vào
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300)
              ),
              child: const Text("Chi tiết", style: TextStyle(fontSize: 9, color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET CON: TIN TỨC (CAROUSEL)
  // --------------------------------------------------------------------------

  Widget _buildNewsCarouselSection() {
    final List<Map<String, String>> news = List.generate(8, (index) => {
      'title': 'Giá lúa gạo hôm nay tăng mạnh $index',
      'date': '${index + 1}/12/2025'
    });

    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _newsController,
            itemCount: news.length,
            padEnds: false,
            itemBuilder: (context, index) {
              return _buildNewsItem(news[index]);
            },
          ),
          Positioned(
            left: 0,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
                onPressed: () {
                  _newsController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black87),
                onPressed: () {
                  _newsController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(Map<String, String> item) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đọc tin: ${item['title']}")));
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4, left: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Icon(Icons.newspaper, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 8),
            Text(item['title']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(item['date']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CÁC WIDGET KHÁC
  // --------------------------------------------------------------------------

  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          if (onTap != null || title == "Phụ phẩm nổi bật")
            GestureDetector(
              onTap: onTap ?? () => context.push('/products'),
              child: const Text("Xem tất cả", style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return FutureBuilder<List<Product>>(
      future: _featuredProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Padding(padding: EdgeInsets.all(16), child: Text("Lỗi tải sản phẩm"));

        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return const Padding(padding: EdgeInsets.all(16), child: Text("Chưa có sản phẩm nào."));
        }

        final displayData = data.take(4).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: displayData.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            return _buildProductItem(displayData[index]);
          },
        );
      },
    );
  }

  Widget _buildProductItem(Product product) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                  product.imageUrls.first,
                  width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(color: Colors.grey[200]),
                )
                    : Container(color: Colors.green.withOpacity(0.1), child: const Center(child: Icon(Icons.grass, color: Colors.green))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(formatCurrency.format(product.price), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}