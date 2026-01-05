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
    // 5 Tabs: Bỏ tab "Chờ đồng bộ" vì không còn dùng tính năng này nữa
    _tabController = TabController(length: 5, vsync: this);
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
            Tab(text: "Chờ xác nhận"),
            Tab(text: "Đang giao"),
            Tab(text: "Hoàn thành"),
            Tab(text: "Đã hủy"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(null),
          _buildOrderList("Chờ xác nhận"),
          _buildOrderList("Đang giao"),
          _buildOrderList("Hoàn thành"),
          _buildOrderList("Đã hủy"),
        ],
      ),
    );
  }

  Widget _buildOrderList(String? statusFilter) {
    Query query = FirebaseFirestore.instance.collection('DonHang').orderBy('ngayDat', descending: true);

    if (statusFilter != null) {
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

    // Logic hiển thị màu sắc
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.assignment;

    if (status == 'Đang giao') { statusColor = Colors.blue; statusIcon = Icons.local_shipping; }
    if (status == 'Hoàn thành') { statusColor = Colors.green; statusIcon = Icons.check_circle; }
    if (status == 'Đã hủy') { statusColor = Colors.grey; statusIcon = Icons.cancel; }

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
        subtitle: Text(
          "Tổng: ${formatCurrency.format(total)}\n$status",
          style: TextStyle(color: statusColor, fontSize: 13, height: 1.5),
        ),
        // --- NÚT HỦY ĐƠN ---
        trailing: (status != 'Hoàn thành' && status != 'Đã hủy')
            ? IconButton(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          tooltip: "Hủy đơn hàng",
          onPressed: () => _confirmAction(
              context: context,
              title: "Hủy đơn hàng này?",
              content: "Hành động này yêu cầu kết nối Server để hoàn trả tồn kho.",
              docId: docId,
              orderCode: data['maDonHang'] ?? '',
              newStatus: 'Đã hủy'
          ),
        ) : const SizedBox(),
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
                        Expanded(child: Text("${item['ten']}", style: const TextStyle(fontWeight: FontWeight.w500))),
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
                      label: const Text("Xác nhận & Giao hàng"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
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
                      onPressed: () => _confirmAction(
                          context: context,
                          title: "Xác nhận hoàn thành?",
                          content: "Đơn hàng sẽ được ghi nhận doanh thu vào hệ thống SQL.",
                          docId: docId,
                          orderCode: data['maDonHang'] ?? '',
                          newStatus: 'Hoàn thành'
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM XỬ LÝ CHUNG CHO CẢ HỦY VÀ HOÀN THÀNH ---
  void _confirmAction({
    required BuildContext context,
    required String title,
    required String content,
    required String docId,
    required String orderCode,
    required String newStatus,
    String? carrier,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Thoát")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              _processUpdate(docId, orderCode, newStatus, carrier);
            },
            child: const Text("Đồng ý"),
          ),
        ],
      ),
    );
  }

  // --- HÀM CORE XỬ LÝ GỌI API ---
  Future<void> _processUpdate(String docId, String orderCode, String newStatus, String? carrier) async {
    // Hiện Loading (Dùng useRootNavigator: true để nó nằm đè lên tất cả)
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true, // <--- THÊM DÒNG NÀY
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    bool serverSuccess = false;

    try {
      // Gọi API lên Server
      serverSuccess = await AdminApiService.pushOrderStatus(
          orderId: orderCode,
          status: newStatus,
          carrier: carrier
      );
    } catch (e) {
      print("Lỗi API: $e");
    } finally {
      // Tắt Loading (Quan trọng: Phải dùng rootNavigator: true để tắt đúng cái dialog vừa hiện)
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    // Xử lý kết quả
    if (serverSuccess) {
      try {
        final updateData = {
          'trangThai': newStatus,
          'ngayCapNhat': DateTime.now()
        };
        if (carrier != null) {
          updateData['donViVanChuyen'] = carrier;
        }

        // Cập nhật Firestore để App tự đổi màu ngay lập tức
        await FirebaseFirestore.instance.collection('DonHang').doc(docId).update(updateData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("✅ Đã cập nhật trạng thái: $newStatus"))
          );
        }
      } catch (e) {
        print("Lỗi Firebase: $e");
      }
    } else {
      if (mounted) {
        _showErrorDialog("Lỗi kết nối Server Visual Studio!\n\nKhông thể cập nhật SQL. Vui lòng kiểm tra Server.");
      }
    }
  }

  void _showShippingPopup(String docId, String orderCode) {
    String? selectedCarrier;
    final carriers = ["Giao Hàng Nhanh", "Viettel Post", "J&T Express", "Shopee Express"];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chọn đơn vị vận chuyển"),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: carriers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => selectedCarrier = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (selectedCarrier != null) {
                Navigator.pop(ctx);
                // Gọi hàm xử lý chung
                _processUpdate(docId, orderCode, 'Đang giao', selectedCarrier);
              }
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Lỗi hệ thống", style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))],
      ),
    );
  }
}