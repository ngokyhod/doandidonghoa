import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cached_network_image/cached_network_image.dart'; // Bỏ comment nếu dùng thư viện này
import '../model/product_model.dart';
import '../service/Product_Service.dart';
import '../service/sync_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller cho Banner
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final PageController _newsController = PageController(viewportFraction: 0.85); // Chỉnh lại viewport cho tin tức dễ nhìn hơn

  late Future<List<Product>> _featuredProductsFuture;

  // --- MỚI: Danh sách tên sản phẩm để gợi ý ---
  List<String> _productSuggestions = [];
  List<String> _bannerImageUrls = [];

  @override
  void initState() {
    super.initState();
    _featuredProductsFuture = ProductService.fetchProducts();
    _loadSuggestions();
    // Gọi đồng bộ dữ liệu nền
    SyncService.syncAll();
  }

  Future<void> _refreshData() async {
    setState(() {
      _featuredProductsFuture = ProductService.fetchProducts();
      _loadSuggestions(); // Load lại cả banner và gợi ý
    });
  }

  void _loadSuggestions() async {
    // Lấy tất cả sản phẩm về chỉ để lấy tên và ảnh banner
    var products = await ProductService.fetchProducts();
    if (mounted) {
      setState(() {
        _productSuggestions = products.map((e) => e.title).toSet().toList();

        // 1. Thử lấy ảnh từ sản phẩm làm banner
        if (products.isNotEmpty) {
          _bannerImageUrls = products
              .where((p) => p.imageUrls.isNotEmpty)
              .take(3)
              .map((p) => p.imageUrls.first)
              .toList();
        }

        // 2. Nếu không có ảnh sản phẩm, dùng ảnh mẫu đẹp (Unsplash)
        if (_bannerImageUrls.isEmpty) {
          _bannerImageUrls = [
            'https://images.unsplash.com/photo-1625246333195-551e5415842d?q=80&w=1000&auto=format&fit=crop', // Ruộng lúa
            'https://images.unsplash.com/photo-1585314062340-f1a5a7c9328d?q=80&w=1000&auto=format&fit=crop', // Gỗ/Sinh khối
            'https://images.unsplash.com/photo-1542601906990-b4d3fb7d5c73?q=80&w=1000&auto=format&fit=crop', // Mầm cây
          ];
        }
        _startBannerAutoPlay();
      });
    }
  }

  void _startBannerAutoPlay() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients && _bannerImageUrls.isNotEmpty) {
        int nextPageIndex = (_currentBannerIndex + 1) % _bannerImageUrls.length;
        _bannerController.animateToPage(
          nextPageIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
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
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.green,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Search + User Avatar)
                _buildHeader(context),

                // 2. Tiện ích (Grid Icon)
                _buildUtilityGrid(),
                const SizedBox(height: 16),

                // 3. Banner Slider
                _buildBannerSection(),
                const SizedBox(height: 24),

                // 4. Sản phẩm nổi bật
                _buildSectionTitle("Phụ phẩm nổi bật", onTap: () => context.push('/products')),
                _buildFeaturedProducts(),

                const SizedBox(height: 24),

                // 5. Quy trình giao dịch
                _buildSectionTitle("Quy trình giao dịch"),
                _buildTransactionProcessSection(),

                const SizedBox(height: 24),

                // 6. Tin tức
                _buildSectionTitle("Tin tức nông nghiệp"),
                _buildNewsCarouselSection(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET CON: HEADER
  // --------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // 1. THANH TÌM KIẾM
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _productSuggestions.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      context.go('/products?search=${Uri.encodeComponent(selection)}');
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            context.go('/products?search=${Uri.encodeComponent(value)}');
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          prefixIcon: GestureDetector(
                            onTap: () {
                              if (textEditingController.text.isNotEmpty) {
                                context.go('/products?search=${Uri.encodeComponent(textEditingController.text)}');
                              }
                            },
                            child: const Icon(Icons.search, color: Colors.grey),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: constraints.maxWidth,
                            color: Colors.white,
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              shrinkWrap: true,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option, style: const TextStyle(fontSize: 14)),
                                  onTap: () => onSelected(option),
                                  dense: true,
                                  leading: const Icon(Icons.search, size: 18, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 2. USER AVATAR (StreamBuilder)
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final isLoggedIn = user != null;

              return GestureDetector(
                onTap: () {
                  if (isLoggedIn) {
                    context.go('/profile');
                  } else {
                    context.push('/login');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLoggedIn ? Colors.green.withOpacity(0.1) : Colors.transparent,
                    border: Border.all(
                        color: isLoggedIn ? Colors.green : Colors.grey.shade400,
                        width: 1.5
                    ),
                    image: (isLoggedIn && user.photoURL != null)
                        ? DecorationImage(
                      image: NetworkImage(user.photoURL!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: (isLoggedIn && user.photoURL != null)
                      ? null
                      : Icon(
                    isLoggedIn ? Icons.person : Icons.account_circle_outlined,
                    color: isLoggedIn ? Colors.green : Colors.grey,
                    size: isLoggedIn ? 24 : 28,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.green, size: 28),
            onPressed: () => _checkLoginAndGo('/profile'), // Tạm trỏ về profile
          ),

          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.green, size: 28),
            onPressed: () => _checkLoginAndGo('/cart'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TIỆN ÍCH, BANNER, SẢN PHẨM...
  // --------------------------------------------------------------------------

  Widget _buildUtilityGrid() {
    final List<Map<String, dynamic>> utilities = [
      {'icon': Icons.recycling, 'label': 'Thu gom', 'route': '/create_scrap_collection_request', 'color': Colors.green},
      {'icon': Icons.chat, 'label': 'CSKH', 'route': '/chatbot', 'color': Colors.orange}, // Sửa lại route CSKH
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
                if (item['route'] == '/chatbot') {
                  context.push('/chatbot'); // Vào thẳng Chatbot không cần login
                } else {
                  _checkLoginAndGo(item['route']);
                }
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
    if (_bannerImageUrls.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _bannerImageUrls.length,
            onPageChanged: (index) => setState(() => _currentBannerIndex = index),
            itemBuilder: (_, index) {
              final imgUrl = _bannerImageUrls[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300]
                ),
                clipBehavior: Clip.antiAlias,
                child: imgUrl.startsWith('http')
                    ? Image.network( // Dùng Image.network cho link web
                  imgUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                )
                    : Image.asset( // Dùng Image.asset cho ảnh trong máy
                  imgUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported)),
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
          _buildStepItem(context, Icons.shopping_cart_checkout, "Đặt hàng", "1", detail: "Khách hàng lựa chọn nông sản, thêm vào giỏ hàng và nhập thông tin địa chỉ nhận hàng.", isLast: false),
          _buildStepItem(context, Icons.verified_user_outlined, "Xác nhận", "2", detail: "Người bán hoặc hệ thống xác nhận đơn hàng. Kiểm tra số lượng tồn kho và chốt đơn.", isLast: false),
          _buildStepItem(context, Icons.local_shipping_outlined, "Vận chuyển", "3", detail: "Đơn vị vận chuyển đến lấy hàng từ nông trại và giao tận tay đến địa chỉ của bạn.", isLast: false),
          _buildStepItem(context, Icons.star_outline, "Đánh giá", "4", detail: "Bạn nhận hàng, kiểm tra chất lượng và đánh giá sao/bình luận cho người bán.", isLast: true),
        ],
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, IconData icon, String title, String step, {required String detail, required bool isLast}) {
    return Expanded(
      child: GestureDetector(
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
            Row(
              children: [
                Expanded(child: Container(height: 2, color: step == "1" ? Colors.transparent : Colors.grey.shade200)),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.withOpacity(0.5), width: 1.5),
                  ),
                  child: Icon(icon, size: 20, color: Colors.green),
                ),
                Expanded(child: Container(height: 2, color: isLast ? Colors.transparent : Colors.grey.shade200)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
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

  Widget _buildNewsCarouselSection() {
    final List<Map<String, String>> news = List.generate(8, (index) => {
      'title': 'Giá lúa gạo hôm nay tăng mạnh - Tin số ${index + 1}',
      'date': '${index + 1}/12/2025'
    });

    return SizedBox(
      height: 120, // Giảm chiều cao cho gọn
      child: PageView.builder(
        controller: _newsController,
        itemCount: news.length,
        padEnds: false,
        itemBuilder: (context, index) {
          return _buildNewsItem(news[index]);
        },
      ),
    );
  }

  Widget _buildNewsItem(Map<String, String> item) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đọc tin: ${item['title']}")));
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4, left: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.newspaper, color: Colors.green, size: 40)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item['title']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(item['date']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    bool isOutOfStock = product.stockQuantity <= 0;
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
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image_not_supported))),
                )
                    : Container(
                    color: Colors.green.withOpacity(0.1),
                    child: const Center(child: Icon(Icons.grass, color: Colors.green))),
              ),
            ),

            // 2. Thông tin chi tiết
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                  ),
                  const SizedBox(height: 4),

                  // Giá tiền
                  Text(
                      formatCurrency.format(product.price),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)
                  ),

                  const SizedBox(height: 4),

                  // --- HIỂN THỊ TỒN KHO ---
                  Row(
                    children: [
                      Icon(
                          Icons.inventory_2_outlined,
                          size: 12,
                          color: isOutOfStock ? Colors.red : Colors.grey[600]
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOutOfStock
                            ? "Hết hàng"
                            : "Kho: ${product.stockQuantity} ${product.unit}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                          color: isOutOfStock ? Colors.red : Colors.grey[700],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}