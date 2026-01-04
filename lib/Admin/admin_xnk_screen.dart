import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminXNKScreen extends StatefulWidget {
  const AdminXNKScreen({super.key});

  @override
  State<AdminXNKScreen> createState() => _AdminXNKScreenState();
}

class _AdminXNKScreenState extends State<AdminXNKScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 2 Tab chính: Kho (Placeholder) và Thu Gom
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: "Quản lý Kho"),
            Tab(text: "Yêu cầu Thu Gom"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const Center(child: Text("Tính năng Quản lý Kho đang phát triển (Nối API sau)")),
          _buildScrapRequestList(),
        ],
      ),
    );
  }

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
    // Mapping trạng thái
    String statusRaw = data['trangThaiXuLy'] ?? 'MoiYeuCau';
    String statusDisplay = "Chờ xử lý";
    Color statusColor = Colors.orange;

    if (statusRaw == 'DaLenLich') { statusDisplay = "Đã lên lịch"; statusColor = Colors.blue; }
    if (statusRaw == 'DangThuGom') { statusDisplay = "Đang thu gom"; statusColor = Colors.purple; }
    if (statusRaw == 'HoanThanh') { statusDisplay = "Hoàn thành"; statusColor = Colors.green; }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.recycling, color: statusColor, size: 32),
        title: Text(data['productName'] ?? 'Phế liệu', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$statusDisplay - ${data['amount']}kg"),
        trailing: IconButton(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          onPressed: () => _updateStatus(docId, 'Huy'), // Logic hủy
        ),
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

                // --- BUTTONS LOGIC ---

                // 1. Nếu Chờ xử lý -> Hiện nút Lên lịch
                if (statusRaw == 'MoiYeuCau')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: const Text("Lên lịch thu gom"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () => _showDatePicker(docId),
                    ),
                  ),

                // 2. Nếu Đã lên lịch -> Nút Bắt đầu
                if (statusRaw == 'DaLenLich')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.start),
                      label: const Text("Bắt đầu thu gom"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      onPressed: () => _updateStatus(docId, 'DangThuGom'),
                    ),
                  ),

                // 3. Nếu Đang thu gom -> Nút Chọn kho & Hoàn thành
                if (statusRaw == 'DangThuGom')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.warehouse),
                      label: const Text("Chọn kho & Hoàn thành"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _showWarehousePopup(docId),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Popup chọn ngày
  void _showDatePicker(String docId) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(), // Không được chọn quá khứ
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      // Cập nhật ngày và trạng thái
      FirebaseFirestore.instance.collection('ThuGom').doc(docId).update({
        'ngayThuGomDuKien': picked.toIso8601String(),
        'trangThaiXuLy': 'DaLenLich'
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lên lịch thu gom")));
    }
  }

  // Popup chọn kho
  void _showWarehousePopup(String docId) {
    String? selectedWarehouse;
    final warehouses = ["Kho A - Quận 1", "Kho B - Thủ Đức", "Kho Tổng Long An"];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chọn kho nhập hàng"),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Danh sách kho", border: OutlineInputBorder()),
          items: warehouses.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
          onChanged: (val) => selectedWarehouse = val,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (selectedWarehouse != null) {
                FirebaseFirestore.instance.collection('ThuGom').doc(docId).update({
                  'khoNhap': selectedWarehouse,
                  'trangThaiXuLy': 'HoanThanh'
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thu gom hoàn tất!")));
              }
            },
            child: const Text("Xác nhận"),
          )
        ],
      ),
    );
  }

  void _updateStatus(String docId, String status) {
    FirebaseFirestore.instance.collection('ThuGom').doc(docId).update({'trangThaiXuLy': status});
  }
}