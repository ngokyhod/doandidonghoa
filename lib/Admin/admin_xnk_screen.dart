import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../model/inventory_model.dart';
import '../service/warehouse_service.dart';
import '../service/admin_api_service.dart';

class AdminXNKScreen extends StatefulWidget {
  const AdminXNKScreen({super.key});

  @override
  State<AdminXNKScreen> createState() => _AdminXNKScreenState();
}

class _AdminXNKScreenState extends State<AdminXNKScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<InventoryItem> _inventoryList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    final data = await WarehouseService.fetchInventory();
    if (mounted) {
      setState(() {
        _inventoryList = data;
        _isLoading = false;
      });
    }
  }

  String _getValidImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) return "";
    if (originalUrl.startsWith('http')) return originalUrl;
    const String baseUrl = 'https://localhost:7240';
    if (originalUrl.startsWith('/')) {
      return '$baseUrl$originalUrl';
    }
    return '$baseUrl/$originalUrl';
  }

  // --- HÀM XỬ LÝ CHÍNH ---
  Future<void> _processScrapUpdate({
    required String docId,
    required String requestId,
    required String newStatus,
    String? date,
    double? weight,
  }) async {
    // Nếu requestId bị rỗng hoặc là docId của firebase thì báo lỗi ngay (vì API cần mã SQL)
    if (requestId == docId || requestId.isEmpty) {
      _showErrorDialog("Lỗi dữ liệu: Đơn hàng chưa có mã đồng bộ từ SQL (maYeuCauSQL).");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool success = false;
    try {
      success = await AdminApiService.updateScrapStatus(
          requestId: requestId,
          status: newStatus,
          date: date,
          weight: weight
      );
    } catch (e) {
      print("Lỗi Call API: $e");
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    if (success) {
      Map<String, dynamic> updateData = {'trangThaiXuLy': newStatus};
      if (date != null) updateData['ngayThuGomDuKien'] = date;
      if (weight != null) updateData['amount'] = weight;

      await FirebaseFirestore.instance.collection('ThuGom').doc(docId).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Đã cập nhật: $newStatus")));
        if (newStatus == 'HoanThanh') _loadInventory();
      }
    } else {
      if (mounted) {
        _showErrorDialog("Lỗi kết nối Visual Studio!\nKhông thể cập nhật trạng thái.");
      }
    }
  }

  // --- POPUPS GIỮ NGUYÊN LOGIC ---
  void _showCompleteDialog(String docId, String requestId, double currentAmount) {
    DateTime selectedDate = DateTime.now();
    TextEditingController weightController = TextEditingController(text: currentAmount.toString());

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận nhập kho"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Hệ thống sẽ cộng vào kho dựa trên mã sản phẩm."),
            const SizedBox(height: 10),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Khối lượng thực tế (kg)", border: OutlineInputBorder(), suffixText: "kg"),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("Ngày nhập kho:"),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030),
                );
                if (picked != null) selectedDate = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              double? finalWeight = double.tryParse(weightController.text);
              if (finalWeight == null || finalWeight <= 0) return;
              Navigator.of(ctx, rootNavigator: true).pop();
              _processScrapUpdate(docId: docId, requestId: requestId, newStatus: 'HoanThanh', date: selectedDate.toIso8601String(), weight: finalWeight);
            },
            child: const Text("Xác nhận"),
          )
        ],
      ),
    );
  }

  void _showDatePicker(String docId, String requestId) async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime(2030),
    );
    if (picked != null) {
      _processScrapUpdate(docId: docId, requestId: requestId, newStatus: 'DaLenLich', date: picked.toIso8601String());
    }
  }

  void _confirmCancel(String docId, String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hủy yêu cầu?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Thoát")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _processScrapUpdate(docId: docId, requestId: requestId, newStatus: 'Huy');
            },
            child: const Text("Xác nhận Hủy"),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Lỗi", style: TextStyle(color: Colors.red)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))],
      ),
    );
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
          labelColor: Colors.green,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: "Tồn Kho Chi Tiết"),
            Tab(text: "Yêu cầu Thu Gom"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInventoryTab(),
          _buildScrapRequestList(),
        ],
      ),
    );
  }

  // --- TAB 1: KHO ---
  Widget _buildInventoryTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_inventoryList.isEmpty) return const Center(child: Text("Kho đang trống hoặc lỗi kết nối"));

    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _inventoryList.length,
        itemBuilder: (context, index) {
          final item = _inventoryList[index];
          String displayImage = "";
          if (item.imageUrls.isNotEmpty) {
            displayImage = _getValidImageUrl(item.imageUrls.first);
          }
          return Card(
            elevation: 2, margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: displayImage.isNotEmpty
                        ? Image.network(displayImage, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[200], width: 70, height: 70, child: const Icon(Icons.broken_image)))
                        : Container(color: Colors.grey[200], width: 70, height: 70, child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.warehouse, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(item.warehouseName, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("Tồn: ${NumberFormat("#,##0").format(item.quantity)} ${item.unit}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TAB 2: THU GOM ---
  Widget _buildScrapRequestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ThuGom').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!.docs;
        if (requests.isEmpty) return const Center(child: Text("Không có yêu cầu thu gom nào"));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final docId = requests[index].id;
            return _buildScrapItem(docId, data);
          },
        );
      },
    );
  }

  Widget _buildScrapItem(String docId, Map<String, dynamic> data) {
    String statusRaw = data['trangThaiXuLy'] ?? 'MoiYeuCau';

    // --- SỬA LỖI Ở ĐÂY ---
    // Ưu tiên lấy mã 'maYeuCauSQL' mà Backend trả về.
    // Nếu không có (do chưa sync hoặc code cũ) thì mới lấy các key khác.
    String requestId = data['maYeuCauSQL'] ?? data['m_YeuCau'] ?? docId;

    double currentAmount = (data['amount'] ?? 0).toDouble();

    // Hiển thị trạng thái
    String statusDisplay = "Chờ xử lý";
    Color statusColor = Colors.orange;
    if (statusRaw == 'DaLenLich') { statusDisplay = "Đã lên lịch"; statusColor = Colors.blue; }
    if (statusRaw == 'DangThuGom') { statusDisplay = "Đang thu gom"; statusColor = Colors.purple; }
    if (statusRaw == 'HoanThanh') { statusDisplay = "Hoàn thành"; statusColor = Colors.green; }
    if (statusRaw == 'Huy') { statusDisplay = "Đã hủy"; statusColor = Colors.red; }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.recycling, color: statusColor, size: 32),
        title: Text(data['productName'] ?? 'Phế liệu', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$statusDisplay - ${data['amount']}kg"),
            // Hiển thị mã để debug xem có đúng mã SQL không
            Text("ID: $requestId", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: (statusRaw != 'HoanThanh' && statusRaw != 'Huy')
            ? IconButton(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          onPressed: () => _confirmCancel(docId, requestId),
        ) : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Người bán: ${data['contactName']} - ${data['contactPhone']}"),
                Text("Địa chỉ: ${data['fullAddress']}"),
                Text("Giá mong muốn: ${data['giaTriMongMuon']} đ"),
                const SizedBox(height: 12),

                if (statusRaw == 'MoiYeuCau')
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month), label: const Text("Lên lịch thu gom"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    onPressed: () => _showDatePicker(docId, requestId),
                  )),

                if (statusRaw == 'DaLenLich')
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    icon: const Icon(Icons.start), label: const Text("Bắt đầu thu gom"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                    onPressed: () => _processScrapUpdate(docId: docId, requestId: requestId, newStatus: 'DangThuGom'),
                  )),

                if (statusRaw == 'DangThuGom')
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle), label: const Text("Xác nhận Hoàn thành"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => _showCompleteDialog(docId, requestId, currentAmount),
                  )),
              ],
            ),
          )
        ],
      ),
    );
  }
}