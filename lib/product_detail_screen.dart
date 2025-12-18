//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cart_service.dart';
// import 'package:firestore_repository.dart';
// import 'package:wishlist_service.dart';
//
// import 'product_model.dart';
//
// class ProductDetailScreen extends ConsumerStatefulWidget {
//   final Product product;
//
//   const ProductDetailScreen({super.key, required this.product});
//
//   @override
//   ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
// }
//
// class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
//   final CartService _cartService = CartService();
//   final WishlistService _wishlistService = WishlistService();
//   final PageController _pageController = PageController();
//
//   int _currentImageIndex = 0;
//   int _quantity = 1;
//   late Map<String, String> _selectedVariants;
//   bool _isAddingToCart = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedVariants = {
//       for (var variant in widget.product.variants)
//         variant.name: variant.options.isNotEmpty ? variant.options.first : ''
//     };
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _addToCart() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       context.push('/login');
//       return;
//     }
//
//     if (widget.product.stockQuantity < _quantity) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số lượng tồn kho không đủ.'), backgroundColor: Colors.orange));
//       return;
//     }
//
//     setState(() => _isAddingToCart = true);
//
//     try {
//       await _cartService.addProductToCart(widget.product, _quantity, _selectedVariants);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Đã thêm vào giỏ hàng thành công!'), backgroundColor: Colors.green),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _isAddingToCart = false);
//       }
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
//     final recommendedProductsStream = ref.watch(recommendedProductsProvider(widget.product.category));
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(widget.product.title),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black87,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildImageGallery(),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(widget.product.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                       ),
//                       StreamBuilder<bool>(
//                         stream: _wishlistService.isFavorite(widget.product.id),
//                         builder: (context, snapshot) {
//                           final isFavorite = snapshot.data ?? false;
//                           return IconButton(
//                             icon: Icon(
//                               isFavorite ? Icons.favorite : Icons.favorite_border,
//                               color: isFavorite ? Colors.red : Colors.grey,
//                               size: 30,
//                             ),
//                             onPressed: () => _wishlistService.toggleFavorite(widget.product.id),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(currencyFormat.format(widget.product.price), style: const TextStyle(fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 12),
//                    Row(
//                     children: [
//                       const Icon(Icons.store, color: Colors.grey, size: 16),
//                       const SizedBox(width: 8),
//                       Text('Bán bởi: ${widget.product.sellerName}', style: const TextStyle(fontSize: 15, color: Colors.grey)),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                    Row(
//                     children: [
//                       Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 16),
//                       const SizedBox(width: 8),
//                       Text('Còn lại: ${widget.product.stockQuantity} ${widget.product.unit}', style: TextStyle(fontSize: 15, color: widget.product.stockQuantity > 0 ? Colors.green : Colors.red)),
//                     ],
//                   ),
//                   const Divider(height: 32),
//
//                   if (widget.product.variants.isNotEmpty)
//                     ..._buildVariantSelectors(),
//
//                    _buildSectionTitle('Số lượng'),
//                   _buildQuantitySelector(),
//
//                   _buildSectionTitle('Mô tả sản phẩm'),
//                   Text(widget.product.description.isNotEmpty ? widget.product.description : 'Chưa có mô tả cho sản phẩm này.', style: const TextStyle(fontSize: 15, height: 1.5)),
//                   const SizedBox(height: 24),
//
//                   if(widget.product.specifications.isNotEmpty)
//                     _buildSectionTitle('Thông số kỹ thuật'),
//                   if(widget.product.specifications.isNotEmpty)
//                     ..._buildSpecificationRows(),
//
//                 ],
//               ),
//             ),
//             _buildSectionTitle('Sản phẩm đề xuất'),
//             SizedBox(
//               height: 250,
//               child: recommendedProductsStream.when(
//                 data: (products) => ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: products.length,
//                   itemBuilder: (context, index) {
//                     final product = products[index];
//                     return SizedBox(
//                       width: 160,
//                       child: Card(
//                         margin: const EdgeInsets.symmetric(horizontal: 8),
//                         child: InkWell(
//                           onTap: () => context.push('/product/${product.id}', extra: product),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Expanded(
//                                 child: ClipRRect(
//                                   borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
//                                   child: Image.network(product.imageUrls.first, fit: BoxFit.cover, width: double.infinity),
//                                 ),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                                 child: Text(currencyFormat.format(product.price), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//                 loading: () => const Center(child: CircularProgressIndicator()),
//                 error: (error, stack) => const Center(child: Text('Lỗi tải sản phẩm đề xuất')),
//               ),
//             ),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//       bottomNavigationBar: _buildBottomBar(currencyFormat),
//     );
//   }
//
//   Widget _buildImageGallery() {
//      if (widget.product.imageUrls.isEmpty) {
//       return Container(height: 250, color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey)));
//     }
//     return Column(
//       children: [
//         SizedBox(
//           height: 280,
//           child: PageView.builder(
//             controller: _pageController,
//             itemCount: widget.product.imageUrls.length,
//             onPageChanged: (index) => setState(() => _currentImageIndex = index),
//             itemBuilder: (context, index) {
//               return Image.network(
//                 widget.product.imageUrls[index],
//                 fit: BoxFit.cover,
//                 loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
//                 errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
//               );
//             },
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: List.generate(widget.product.imageUrls.length, (index) {
//             return Container(
//               width: 8.0, height: 8.0, margin: const EdgeInsets.symmetric(horizontal: 4.0),
//               decoration: BoxDecoration(shape: BoxShape.circle, color: _currentImageIndex == index ? Colors.green : Colors.grey[300]),
//             );
//           }),
//         ),
//       ],
//     );
//   }
//
//   List<Widget> _buildVariantSelectors() {
//     /* ... (same as before) ... */
//         return widget.product.variants.map((variant) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(variant.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8.0,
//             children: variant.options.map((option) {
//               final isSelected = _selectedVariants[variant.name] == option;
//               return ChoiceChip(
//                 label: Text(option),
//                 selected: isSelected,
//                 onSelected: (selected) {
//                   setState(() {
//                     _selectedVariants[variant.name] = option;
//                   });
//                 },
//                 selectedColor: Colors.green.withOpacity(0.2),
//                 backgroundColor: Colors.grey[200],
//                 labelStyle: TextStyle(color: isSelected ? Colors.green[800] : Colors.black),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 16),
//         ],
//       );
//     }).toList();
//   }
//    Widget _buildQuantitySelector() {
//     return Row(
//       children: [
//         IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1)),
//         Text(_quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _quantity++)),
//       ],
//     );
//   }
//
//
//   List<Widget> _buildSpecificationRows() {
//     /* ... (same as before) ... */
//         return widget.product.specifications.entries.map((entry) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8.0),
//         child: Row(
//           children: [
//             Expanded(flex: 2, child: Text(entry.key, style: TextStyle(color: Colors.grey[600]))),
//             Expanded(flex: 3, child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w500))),
//           ],
//         ),
//       );
//     }).toList();
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 16.0),
//       child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//     );
//   }
//
//   Widget _buildBottomBar(NumberFormat currencyFormat) {
//     final total = widget.product.price * _quantity;
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
//         borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Tổng cộng', style: TextStyle(color: Colors.grey)),
//               Text(currencyFormat.format(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
//             ],
//           ),
//           ElevatedButton.icon(
//             onPressed: widget.product.stockQuantity > 0 && !_isAddingToCart ? _addToCart : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               disabledBackgroundColor: Colors.grey[300],
//             ),
//             icon: _isAddingToCart ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add_shopping_cart),
//             label: Text(_isAddingToCart ? 'Đang thêm...' : (widget.product.stockQuantity > 0 ? 'Thêm vào giỏ' : 'Hết Hàng'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           ),
//         ],
//       ),
//     );
//   }
// }
