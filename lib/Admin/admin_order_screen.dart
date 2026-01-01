import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_api_service.dart';
import 'package:intl/intl.dart';
import '../theme_notifier.dart';
import 'widgets/admin_notification_bell.dart'; // IMPORT WIDGET CHUÔNG XỊN

class AdminOrderScreen extends ConsumerStatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  ConsumerState<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends ConsumerState<AdminOrderScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _selectedStatus = "All";

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F6F9),
      appBar: AppBar(
        title: Text('Quản lý Đơn Hàng', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          // SỬA TẠI ĐÂY: Sử dụng AdminNotificationBell thay vì IconButton thông thường
          const AdminNotificationBell(), 
          const CircleAvatar(radius: 15, backgroundColor: Colors.blue, child: Text('PH', style: TextStyle(fontSize: 10, color: Colors.white))),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(isDarkMode),
          Expanded(child: _buildOrderList(isDarkMode, cardColor)),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(bool isDarkMode) {
    final statuses = ["All", "Chờ xác nhận", "Đang giao", "Hoàn thành", "Đã hủy"];
    return Container(
      height: 50,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final s = statuses[index];
          final isSelected = _selectedStatus == s;
          return GestureDetector(
            onTap: () => setState(() => _selectedStatus = s),
            child: Container(
              margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(s, style: TextStyle(color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black), fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(bool isDarkMode, Color cardColor) {
    return FutureBuilder<List<dynamic>>(
      future: AdminApiService.getOrders(status: _selectedStatus),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!;
        if (orders.isEmpty) return Center(child: Text("Không có đơn hàng nào", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final o = orders[index];
            return Card(
              color: cardColor,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Đơn: ${o['maDonHang']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        Text(currencyFormat.format(o['tongTien'] ?? 0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
                      ],
                    ),
                    const Divider(height: 24),
                    _infoRow(Icons.person_outline, o['tenNguoiNhan'] ?? '', isDarkMode),
                    _infoRow(Icons.calendar_today_outlined, o['ngayDat'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(o['ngayDat'])) : '', isDarkMode),
                    _infoRow(Icons.shopping_bag_outlined, '${o['soLuongSanPham']} sản phẩm', isDarkMode),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statusBadge(o['trangThai'] ?? ''),
                        const Spacer(),
                        OutlinedButton(onPressed: () {}, child: const Text('Xem')),
                        const SizedBox(width: 8),
                        if (o['trangThai'] == 'Chờ xác nhận')
                          ElevatedButton(
                            onPressed: () => _updateStatus(o['maDonHang'], "Đang giao"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: const Text('Xác nhận'),
                          ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateStatus(String id, String status) async {
    bool success = await AdminApiService.updateOrderStatus(id, status);
    if (success) {
      setState(() {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật trạng thái")));
    }
  }

  Widget _infoRow(IconData icon, String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(text, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white70 : Colors.black87))]),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.orange;
    if (status == "Hoàn thành") color = Colors.green;
    if (status == "Đã hủy") color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
