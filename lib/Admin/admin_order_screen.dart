import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../service/admin_api_service.dart';

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
    // 6 Tabs: Thêm tab Đã hủy để quản lý đơn hủy
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: "Tất cả"),
            Tab(text: "Chờ đồng bộ"),
            Tab(text: "Chờ xác nhận"),
            Tab(text: "Đang giao"),
            Tab(text: "Hoàn thành"),
            Tab(text: "Đã hủy"), // Thêm tab này
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(null), // Tất cả
          _buildOrderList("sync_false"),
          _buildOrderList("Chờ xác nhận"),
          _buildOrderList("Đang giao"),
          _buildOrderList("Hoàn thành"),
          _buildOrderList("Đã hủy"), // List đơn hủy
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
            final docId = orders[index].id;
            return _buildOrderItem(docId, orderData);
          },
        );
      },
    );
  }

  Widget _buildOrderItem(String docId, Map<String, dynamic> data) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final String status = data['trangThai'] ?? 'Chờ xác nhận';
    final double total = (data['tongTien'] ?? 0).toDouble();
    final bool isSync = data['isSync'] ?? true; // Quan trọng để biết Backend có chạy không

    // --- MÀU SẮC TRẠNG THÁI ---
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.assignment;

    if (status == 'Đang giao') { statusColor = Colors.blue; statusIcon = Icons.local_shipping; }
    if (status == 'Hoàn thành') { statusColor = Colors.green; statusIcon = Icons.check_circle; }
    if (status == 'Đã hủy') { statusColor = Colors.grey; statusIcon = Icons.cancel; }

    // Nếu chưa sync (Backend tắt) thì báo đỏ
    if (!isSync) statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(statusIcon, color: statusColor),
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
              const Text("⚠️ Chưa đồng bộ SQL (Server lỗi/tắt)", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))
            else
              Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        // --- THAY NÚT XÓA BẰNG NÚT HỦY (Chỉ hiện khi chưa Hoàn thành/Đã hủy) ---
        trailing: (status != 'Hoàn thành' && status != 'Đã hủy')
            ? IconButton(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          tooltip: "Hủy đơn hàng",
          onPressed: () => _confirmCancelOrder(docId, data['maDonHang']),
        )
            : const SizedBox(), // Ẩn nút nếu đã xong/hủy
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Chi tiết đơn hàng:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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

                // --- NÚT UPDATE TRẠNG THÁI ---
                if (status == 'Chờ xác nhận')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.local_shipping),
                      label: const Text("Xác nhận & Chọn ĐVVC"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      // Truyền thêm data['maDonHang'] làm tham số thứ 2
                      onPressed: () => _showShippingPopup(docId, data['maDonHang'] ?? ''),
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

  // --- LOGIC HỦY ĐƠN (THAY CHO DELETE) ---
  void _confirmCancelOrder(String docId, String? code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Hủy đơn hàng $code?"),
        content: const Text("Đơn hàng sẽ chuyển sang trạng thái 'Đã hủy'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Quay lại")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng popup trước

              // Hiện loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              // A. GỌI API PUSH LÊN SERVER (Cách chính thống)
              bool success = await AdminApiService.pushOrderStatus(
                  orderId: code ?? "",
                  status: "Đã hủy"
              );

              // Tắt loading
              if (mounted) Navigator.pop(context);

              if (success) {
                // Nếu thành công: Không cần làm gì cả,
                // Server đã update Firebase -> Stream sẽ tự cập nhật UI
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Server đã xác nhận hủy đơn!")));
              } else {
                // B. FALLBACK: NẾU SERVER CHẾT -> UPDATE TRỰC TIẾP FIREBASE (Cách dự phòng)
                FirebaseFirestore.instance.collection('DonHang').doc(docId).update({
                  'trangThai': 'Đã hủy',
                  'isSync': false, // Báo đỏ: Chưa đồng bộ
                  'ngayCapNhat': DateTime.now()
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ Server không phản hồi. Đã lưu tạm offline!")),
                );
              }
            },
            child: const Text("Xác nhận Hủy"),
          ),
        ],
      ),
    );
  }

  // Popup chọn đơn vị vận chuyển (Giữ nguyên)
  void _showShippingPopup(String docId, String orderCode) { // Thêm orderCode tham số
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
            onPressed: () async {
              if (selectedCarrier != null) {
                Navigator.pop(ctx);

                // Tương tự: Gọi API Push lên trước
                bool success = await AdminApiService.pushOrderStatus(
                    orderId: orderCode,
                    status: "Đang giao",
                    carrier: selectedCarrier
                );

                if (!success) {
                  // Fallback nếu lỗi
                  FirebaseFirestore.instance.collection('DonHang').doc(docId).update({
                    'trangThai': 'Đang giao',
                    'donViVanChuyen': selectedCarrier,
                    'isSync': false
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Server lỗi. Đã lưu offline.")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã chuyển sang Đang giao")));
                }
              }
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String docId, String newStatus) {
    FirebaseFirestore.instance.collection('DonHang').doc(docId).update({
      'trangThai': newStatus,
      'isSync': false // Trigger Backend
    });
  }
}