import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_api_service.dart';
import '../theme_notifier.dart';

class AdminXNKScreen extends ConsumerStatefulWidget {
  const AdminXNKScreen({super.key});

  @override
  ConsumerState<AdminXNKScreen> createState() => _AdminXNKScreenState();
}

class _AdminXNKScreenState extends ConsumerState<AdminXNKScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F6F9),
      appBar: AppBar(
        title: Text('Quản lý Kho & Thu gom', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18)),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(icon: Icon(Icons.notifications_none, color: isDarkMode ? Colors.white70 : Colors.grey), onPressed: () {}),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Tồn Kho'),
            Tab(text: 'Thu gom Phụ phẩm'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTonKhoTab(isDarkMode, cardColor, textColor),
          _buildThuGomTab(isDarkMode, cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildTonKhoTab(bool isDarkMode, Color cardColor, Color textColor) {
    return FutureBuilder<List<dynamic>>(
      future: AdminApiService.getProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        
        return Column(
          children: [
            _buildQuickStats(isDarkMode, cardColor, textColor),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.inventory_2, color: Colors.blue),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['tenSanPham'] ?? 'N/A', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                              Text('Mã SP: ${item['maSanPham']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${item['tonKho'] ?? 0} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                            const Text('Hiện có', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(bool isDarkMode, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _statMiniCard('ĐÃ LÊN LỊCH', '12', Icons.calendar_today, Colors.blue, isDarkMode, cardColor)),
          const SizedBox(width: 12),
          Expanded(child: _statMiniCard('HOÀN THÀNH', '8', Icons.check_circle, Colors.green, isDarkMode, cardColor)),
        ],
      ),
    );
  }

  Widget _statMiniCard(String label, String value, IconData icon, Color color, bool isDarkMode, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black, fontSize: 16)),
              Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildThuGomTab(bool isDarkMode, Color cardColor, Color textColor) {
    return FutureBuilder<List<dynamic>>(
      future: AdminApiService.getCollections(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mã YC: ${item['id']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      _statusBadge(item['trangThai'] ?? 'Chờ xử lý'),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoLine(Icons.person_outline, item['tenNguoiYeuCau'] ?? ''),
                  _infoLine(Icons.location_on_outlined, item['diaChi'] ?? ''),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('KHỐI LƯỢNG', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text('${item['khoiLuong'] ?? 0} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Xác nhận thu gom', style: TextStyle(fontSize: 12)),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))]),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
