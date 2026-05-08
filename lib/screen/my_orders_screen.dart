import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../service/my_order_scrap_service.dart';
import '../services/my_order_scrap_service.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đơn mua của tôi", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // THAY STREAM BẰNG FUTURE BUILDER GỌI API
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: MyOrderScrapService().fetchOrders(user?.uid ?? ""),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) return const Center(child: Text("Bạn chưa có đơn hàng nào"));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index];
              final status = data['trangThai'] ?? 'Chờ xử lý';
              final ngayDatStr = data['ngayDat'] != null ? DateTime.parse(data['ngayDat']).toString().substring(0, 10) : 'N/A';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Mã đơn: ${data['maDonHang']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(status, style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 20),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(width: 50, height: 50, color: Colors.green.shade50, child: const Icon(Icons.shopping_basket, color: Colors.green)),
                        title: Text("Ngày đặt: $ngayDatStr"),
                        subtitle: Text("Địa chỉ: ${data['diaChiGiao'] ?? '...'}", maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('hủy')) return Colors.red;
    if (status.toLowerCase().contains('hoàn thành')) return Colors.green;
    return Colors.orange;
  }
}