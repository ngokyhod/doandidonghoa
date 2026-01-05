import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- IMPORT MODEL VÀ SERVICE ---
import '../model/inventory_model.dart';
import '../service/warehouse_service.dart';

class AdminXNKScreen extends StatefulWidget {
  const AdminXNKScreen({super.key});

  @override
  State<AdminXNKScreen> createState() => _AdminXNKScreenState();
}

class _AdminXNKScreenState extends State<AdminXNKScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- BIẾN CHO PHẦN QUẢN LÝ KHO ---
  List<InventoryItem> _inventoryList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInventory(); // Load dữ liệu ngay khi vào
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

    // Thay IP này bằng IP máy tính của bạn (KHÔNG DÙNG LOCALHOST CHO ANDROID THẬT/GIẢ LẬP)
    // Ví dụ: 'http://192.168.1.X:7240'
    const String baseUrl = 'https://localhost:7240'; // Dùng 10.0.2.2 nếu chạy máy ảo Android

    if (originalUrl.startsWith('/')) {
      return '$baseUrl$originalUrl';
    }
    return '$baseUrl/$originalUrl';
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
            Tab(text: "Tồn Kho Chi Tiết"), // Đổi tên Tab
            Tab(text: "Yêu cầu Thu Gom"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInventoryTab(), // Tab mới
          _buildScrapRequestList(), // Tab cũ giữ nguyên
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_inventoryList.isEmpty) {
      return const Center(child: Text("Kho đang trống hoặc lỗi kết nối"));
    }

    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _inventoryList.length,
        itemBuilder: (context, index) {
          final item = _inventoryList[index];
          final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

          // Lấy link ảnh đầu tiên và xử lý
          String displayImage = "";
          if (item.imageUrls.isNotEmpty) {
            displayImage = _getValidImageUrl(item.imageUrls.first);
          }

          return Card(
            elevation: 2, // Thêm độ nổi giống bên Product
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // --- PHẦN ẢNH (GIỐNG HỆT PRODUCT) ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: displayImage.isNotEmpty
                        ? Image.network(
                        displayImage,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => Container(color: Colors.grey[200], width: 70, height: 70, child: const Icon(Icons.broken_image))
                    )
                        : Container(color: Colors.grey[200], width: 70, height: 70, child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 16),

                  // --- PHẦN THÔNG TIN ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên sản phẩm
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Tên Kho (Thay cho giá tiền bên Product)
                        Row(
                          children: [
                            const Icon(Icons.warehouse, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(item.warehouseName, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Số lượng tồn kho (Thay cho dòng tồn kho bên Product)
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                                "Tồn: ${NumberFormat("#,##0").format(item.quantity)} ${item.unit}",
                                style: const TextStyle(fontSize: 12, color: Colors.black87)
                            ),
                          ],
                        ),
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
  // ============================================================
  // TAB 2: YÊU CẦU THU GOM (GIỮ NGUYÊN CODE CỦA BẠN)
  // ============================================================
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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

  // Popup chọn kho cho Thu Gom (Hardcode tạm thời hoặc có thể nối API sau)
  void _showWarehousePopup(String docId) {
    String? selectedWarehouse;
    // Tạm thời dùng list cứng, sau này có thể dùng _warehouses.map... để lấy tên kho thật
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