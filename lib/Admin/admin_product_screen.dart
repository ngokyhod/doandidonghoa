import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_api_service.dart';
import 'package:intl/intl.dart';
import '../theme_notifier.dart';
import 'edit_product_screen.dart';
import 'widgets/admin_notification_bell.dart';

class AdminProductScreen extends ConsumerStatefulWidget {
  const AdminProductScreen({super.key});

  @override
  ConsumerState<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends ConsumerState<AdminProductScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  void _showProductDetail(Map<String, dynamic> p, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          height: 250,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 100, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(p['tenSanPham'] ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Đang bán', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(currencyFormat.format(p['gia'] ?? 0), style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold)),
                    const Divider(height: 40),
                    _detailRow('Mã sản phẩm', p['maSanPham'] ?? 'N/A', isDarkMode),
                    _detailRow('Tồn kho thực tế', '${p['tonKho'] ?? 0} kg', isDarkMode),
                    _detailRow('Loại sản phẩm', 'Phụ phẩm nông nghiệp', isDarkMode),
                    const SizedBox(height: 24),
                    Text('Mô tả chi tiết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                    const SizedBox(height: 8),
                    Text(
                      'Đây là thông tin mô tả chi tiết của sản phẩm được lấy từ hệ thống quản lý Saika Hana. Sản phẩm này đảm bảo chất lượng đầu ra và quy trình thu gom nghiêm ngặt.',
                      style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditProductScreen(product: p)),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Chỉnh sửa SP'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {}),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F6F9),
      appBar: AppBar(
        title: Text('Quản lý Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          const AdminNotificationBell(),
          const CircleAvatar(radius: 15, backgroundColor: Colors.blue, child: Text('PH', style: TextStyle(fontSize: 10, color: Colors.white))),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: AdminApiService.getProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!;
          
          // Tính toán các con số thực tế từ danh sách API trả về
          final int totalProducts = products.length;
          final int outOfStock = products.where((p) => (p['tonKho'] ?? 0) <= 0).length;
          final int inStock = totalProducts - outOfStock;

          return Column(
            children: [
              _buildStatsHeader(isDarkMode, cardColor, totalProducts, outOfStock, inStock),
              _buildSearchBar(isDarkMode),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () => _showProductDetail(p, isDarkMode),
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                        title: Text(p['tenSanPham'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kho: ${p['tonKho']} - ${p['maSanPham']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(currencyFormat.format(p['gia'] ?? 0), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsHeader(bool isDarkMode, Color cardColor, int total, int outOfStock, int inStock) {
    return Container(
      color: cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem('Tổng sản phẩm', '$total', isDarkMode ? Colors.white : Colors.black),
          _statItem('Hết hàng', '$outOfStock', Colors.red),
          _statItem('Đang bán', '$inStock', Colors.green),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên, mã SP...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
