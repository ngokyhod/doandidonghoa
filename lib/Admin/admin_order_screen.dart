import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 5 Tabs: Tất cả, Chờ đồng bộ, Chờ xác nhận, Đang giao, Hoàn thành
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0, // Ẩn toolbar, chỉ hiện TabBar
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: "Tất cả"),
            Tab(text: "Chờ đồng bộ"), // Tab mới
            Tab(text: "Chờ xác nhận"),
            Tab(text: "Đang giao"),
            Tab(text: "Hoàn thành"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(null), // Tất cả
          _buildOrderList("sync_false"), // Logic lọc riêng cho sync
          _buildOrderList("Chờ xác nhận"),
          _buildOrderList("Đang giao"),
          _buildOrderList("Hoàn thành"),
        ],
      ),
    );
  }

  Widget _buildOrderList(String? statusFilter) {
    Query query = FirebaseFirestore.instance.collection('DonHang').orderBy('ngayDat', descending: true);

    if (statusFilter == "sync_false") {
      query = query.where('isSync', isEqualTo: false);
    } else if (statusFilter != null) {
      query = query.where('trangThai', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final orders = snapshot.data!.docs;
        if (orders.isEmpty) return const Center(child: Text("Chưa có đơn hàng nào"));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderData = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;
            return _buildOrderItem(orderId, orderData);
          },
        );
      },
    );
  }

  Widget _buildOrderItem(String docId, Map<String, dynamic> data) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final String status = data['trangThai'] ?? 'Chờ xác nhận';
    final double total = (data['tongTien'] ?? 0).toDouble();
    final bool isSync = data['isSync'] ?? true;

    Color statusColor = Colors.orange;
    if (status == 'Đang giao') statusColor = Colors.blue;
    if (status == 'Hoàn thành') statusColor = Colors.green;
    if (!isSync) statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.assignment, color: statusColor),
        ),
        title: Text(
          "Mã: ${data['maDonHang'] ?? '...'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tổng: ${formatCurrency.format(total)}"),
            if (!isSync)
              const Text("⚠️ Chưa đồng bộ SQL", style: TextStyle(color: Colors.red, fontSize: 12))
            else
              Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteOrder(docId),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Chi tiết đơn hàng:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Hiển thị list sản phẩm
                ...(data['items'] as List<dynamic>? ?? []).map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text("${item['ten']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text("x${item['soLuong']}"),
                        const SizedBox(width: 8),
                        Text(formatCurrency.format(item['gia'])),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(),
                const Text("Địa chỉ:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(data['nguoiNhan']?['diaChi'] ?? 'Không có địa chỉ'),
                const SizedBox(height: 16),

                // --- CÁC NÚT XỬ LÝ TRẠNG THÁI ---
                if (status == 'Chờ xác nhận')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.local_shipping),
                      label: const Text("Xác nhận & Chọn ĐVVC"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      onPressed: () => _showShippingPopup(docId),
                    ),
                  ),

                if (status == 'Đang giao')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Xác nhận Hoàn Thành"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () => _updateStatus(docId, 'Hoàn thành'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Popup chọn đơn vị vận chuyển
  void _showShippingPopup(String docId) {
    String? selectedCarrier;
    final carriers = ["Giao Hàng Nhanh", "Viettel Post", "J&T Express", "Shopee Express"];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cập nhật vận chuyển"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Chọn đơn vị vận chuyển", border: OutlineInputBorder()),
              items: carriers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => selectedCarrier = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (selectedCarrier != null) {
                // Cập nhật trạng thái và ĐVVC
                FirebaseFirestore.instance.collection('DonHang').doc(docId).update({
                  'trangThai': 'Đang giao',
                  'donViVanChuyen': selectedCarrier,
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã chuyển sang Đang giao")));
              }
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String docId, String newStatus) {
    FirebaseFirestore.instance.collection('DonHang').doc(docId).update({'trangThai': newStatus});
  }

  void _deleteOrder(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa đơn hàng?"),
        content: const Text("Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('DonHang').doc(docId).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}