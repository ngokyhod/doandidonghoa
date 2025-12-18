
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'product_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  // State for filtering and searching
  String _searchQuery = '';
  String _sortBy = 'price_asc'; // Default sort
  RangeValues _priceRange = const RangeValues(0, 10000000); // Default price range
  String? _selectedCategory;
  int _currentBannerIndex = 0;

  final List<String> _bannerImageUrls = [
    'assets/images/Banner/banner1.png',
    'assets/images/Banner/banner2.png',
    'assets/images/Banner/banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _startBannerAutoPlay();
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
    _bannerTimer?.cancel();
    super.dispose();
  }


  void _navigateToProtected(String route) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.push('/login');
    } else {
      context.push(route);
    }
  }
  
  // Method to build the Firestore query based on current filters
  Query _buildProductQuery() {
    Query query = FirebaseFirestore.instance.collection('products');

    if (_searchQuery.isNotEmpty) {
       query = query.where('title', isGreaterThanOrEqualTo: _searchQuery)
                   .where('title', isLessThanOrEqualTo: '$_searchQuery\uf8ff');
    }

    if (_selectedCategory != null) {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    query = query.where('price', isGreaterThanOrEqualTo: _priceRange.start)
                 .where('price', isLessThanOrEqualTo: _priceRange.end);

    switch (_sortBy) {
      case 'price_desc':
        query = query.orderBy('price', descending: true);
        break;
      case 'latest':
        query = query.orderBy('createdAt', descending: true);
        break;
      default:
        query = query.orderBy('price', descending: false);
    }

    return query;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FilterBottomSheet(
          initialPriceRange: _priceRange,
          initialSortBy: _sortBy,
          initialCategory: _selectedCategory,
          onApplyFilter: (newPriceRange, newSortBy, newCategory) {
            setState(() {
              _priceRange = newPriceRange;
              _sortBy = newSortBy;
              _selectedCategory = newCategory;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
           // Search and Filter Bar
        Container(
          color: theme.appBarTheme.backgroundColor,
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm nông sản...',
                          prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10.0),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.filter_list, color: Colors.white), onPressed: _showFilterSheet),
              ],
            ),
          ),
        ),
          SizedBox(
            height: 200.0,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _bannerImageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Image.asset(
                    _bannerImageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
                            Text('Lỗi tải ảnh', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
           const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _bannerImageUrls.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _bannerController.animateToPage(entry.key, duration: const Duration(milliseconds: 300), curve: Curves.easeIn),
                  child: Container(
                    width: 12.0,
                    height: 12.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withOpacity(_currentBannerIndex == entry.key ? 0.9 : 0.4),
                    ),
                  ),
                );
              }).toList(),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildProductQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi tải sản phẩm: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.docs;
                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: theme.disabledColor),
                        const SizedBox(height: 16),
                        Text(
                          "Không tìm thấy sản phẩm nào phù hợp.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: theme.disabledColor),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final product = Product.fromFirestore(data[index]);
                    return _buildProductCard(context, product);
                  },
                  itemCount: data.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductCard(BuildContext context, Product product) {
    final theme = Theme.of(context);
      return GestureDetector(
      onTap: () => context.push('/product/${product.id}', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: product.imageUrls.isNotEmpty
                    ? Image.asset(product.imageUrls.first, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey));
                        })
                    : Container(color: theme.primaryColor.withOpacity(0.1), child: Center(child: Icon(Icons.grass, size: 40, color: theme.primaryColor))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                   Text(product.sellerName, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(_currencyFormat.format(product.price), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for the Filter Bottom Sheet UI
class FilterBottomSheet extends StatefulWidget {
  final RangeValues initialPriceRange;
  final String initialSortBy;
  final String? initialCategory;
  final Function(RangeValues, String, String?) onApplyFilter;

  const FilterBottomSheet({
    super.key,
    required this.initialPriceRange,
    required this.initialSortBy,
    required this.initialCategory,
    required this.onApplyFilter,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _currentPriceRange;
  late String _currentSortBy;
  String? _currentCategory;

  final List<String> _categories = ["Đã qua xử lý", "Phụ phẩm thô", "Thức ăn chăn nuôi", "Phân bón"];

  @override
  void initState() {
    super.initState();
    _currentPriceRange = widget.initialPriceRange;
    _currentSortBy = widget.initialSortBy;
    _currentCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lọc & Sắp xếp', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          Text('Khoảng giá', style: theme.textTheme.titleLarge),
          RangeSlider(
            values: _currentPriceRange,
            min: 0,
            max: 10000000, 
            divisions: 100,
            labels: RangeLabels(
              NumberFormat.compactCurrency(locale: 'vi_VN').format(_currentPriceRange.start),
              NumberFormat.compactCurrency(locale: 'vi_VN').format(_currentPriceRange.end),
            ),
            onChanged: (values) {
              setState(() {
                _currentPriceRange = values;
              });
            },
          ),
          const SizedBox(height: 24),

          Text('Danh mục', style: theme.textTheme.titleLarge),
          Wrap(
            spacing: 8.0,
            children: _categories.map((category) {
              final isSelected = _currentCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _currentCategory = selected ? category : null;
                  });
                },
                selectedColor: theme.primaryColor.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Text('Sắp xếp theo', style: theme.textTheme.titleLarge),
          DropdownButtonFormField<String>(
            value: _currentSortBy,
            items: const [
              DropdownMenuItem(value: 'price_asc', child: Text('Giá tăng dần')),
              DropdownMenuItem(value: 'price_desc', child: Text('Giá giảm dần')),
              DropdownMenuItem(value: 'latest', child: Text('Mới nhất')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentSortBy = value;
                });
              }
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onApplyFilter(_currentPriceRange, _currentSortBy, _currentCategory);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: theme.colorScheme.onPrimary),
              child: const Text('ÁP DỤNG', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
