import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/my_order_scrap_service.dart';
 // Đổi đường dẫn import

class MyScrapRequestsScreen extends StatelessWidget {
  const MyScrapRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yêu cầu thu gom", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // THAY STREAM BẰNG FUTURE BUILDER GỌI API
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: MyOrderScrapService().fetchScrapRequests(user?.uid ?? ""),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) return const Center(child: Text("Không có yêu cầu nào"));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index];
              final status = data['trangThai'] ?? 'Đang chờ';
              final ngayYeuCauStr = data['ngayYeuCau'] != null ? DateTime.parse(data['ngayYeuCau']).toString().substring(0, 10) : 'N/A';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.recycling, color: Colors.white)),
                  title: Text("Mã YC: ${data['maYeuCau']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Ngày gửi: $ngayYeuCauStr\nGhi chú: ${data['ghiChu'] ?? 'Không có'}"),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: _getScrapStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(status, style: TextStyle(color: _getScrapStatusColor(status), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getScrapStatusColor(String status) {
    if (status.toLowerCase().contains('hoàn thành')) return Colors.green;
    if (status.toLowerCase().contains('hủy')) return Colors.red;
    return Colors.orange;
  }
}