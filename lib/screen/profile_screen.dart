import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) context.go('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng xuất: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F6F9),
      appBar: AppBar(
        title: Text('Hồ sơ cá nhân', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final String name = userData['fullName'] ?? _user!.displayName ?? 'Người dùng';
          final String phone = userData['phoneNumber'] ?? _user!.phoneNumber ?? 'Chưa cập nhật SĐT';
          final String photoUrl = userData['photoURL'] ?? _user!.photoURL ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(name, phone, photoUrl, isDarkMode),
                const SizedBox(height: 20),

                // --- PHẦN 1: THỐNG KÊ TRẠNG THÁI ĐƠN HÀNG & THU GOM ---
                _buildOrderStatsSection(isDarkMode),

                const SizedBox(height: 20),

                // --- PHẦN 2: ĐƠN HÀNG MỚI NHẤT (LẤY REALTIME) ---
                _buildNewestOrderCard(isDarkMode),

                const SizedBox(height: 20),
                _buildMenuList(isDarkMode),
                const SizedBox(height: 20),
                _buildLogoutButton(context),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String phone, String photoUrl, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.green.shade100, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.green.shade100,
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.green) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Text(phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50.withOpacity(isDarkMode ? 0.1 : 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Thành viên', style: TextStyle(color: Colors.green, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET MỚI: THỐNG KÊ REALTIME ---
  Widget _buildOrderStatsSection(bool isDarkMode) {
    // Kết hợp Stream: Lấy cả DonHang và ThuGom
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('DonHang').where('uid', isEqualTo: _user!.uid).snapshots(),
      builder: (context, orderSnapshot) {
        return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ThuGom').where('uid', isEqualTo: _user!.uid).snapshots(),
            builder: (context, scrapSnapshot) {

              // Tính toán số lượng badge
              int pendingCount = 0;
              int shippingCount = 0;
              int scrapCount = 0;

              if (orderSnapshot.hasData) {
                final orders = orderSnapshot.data!.docs;
                pendingCount = orders.where((d) {
                  final st = (d.data() as Map)['trangThai'] ?? '';
                  return st == 'Chờ xác nhận' || st == 'Chờ đồng bộ' || st == 'Đang xử lý';
                }).length;

                shippingCount = orders.where((d) => (d.data() as Map)['trangThai'] == 'Đang giao').length;
              }

              if (scrapSnapshot.hasData) {
                // Đếm số yêu cầu thu gom đang chờ/xử lý
                scrapCount = scrapSnapshot.data!.docs.where((d) {
                  final st = (d.data() as Map)['trangThaiXuLy'] ?? '';
                  return st != 'HoanThanh' && st != 'Huy';
                }).length;
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hoạt động của tôi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
                        // Nút này có thể dẫn đến trang lịch sử chi tiết
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to Order History Screen
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng xem lịch sử đang phát triển")));
                          },
                          child: const Text('Xem tất cả >', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderStatusItem(Icons.assignment_outlined, 'Đơn mua', isDarkMode, badgeCount: pendingCount),
                        _buildOrderStatusItem(Icons.local_shipping_outlined, 'Vận chuyển', isDarkMode, badgeCount: shippingCount),
                        // Thay đổi icon đánh giá thành icon Thu Gom để khách theo dõi đơn bán
                        _buildOrderStatusItem(Icons.recycling, 'Thu gom', isDarkMode, badgeCount: scrapCount),
                        _buildOrderStatusItem(Icons.history, 'Lịch sử', isDarkMode),
                      ],
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildOrderStatusItem(IconData icon, String label, bool isDarkMode, {int badgeCount = 0}) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: isDarkMode ? Colors.white70 : Colors.green.shade700),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5)
                  ),
                  child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black87)),
      ],
    );
  }

  // --- WIDGET MỚI: THẺ ĐƠN HÀNG MỚI NHẤT ---
  Widget _buildNewestOrderCard(bool isDarkMode) {
    // Lấy 1 đơn hàng mới nhất của user này
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('DonHang')
          .where('uid', isEqualTo: _user!.uid)
          .orderBy('ngayDat', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(); // Ẩn đi nếu chưa có đơn nào
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        // Parse dữ liệu an toàn
        final status = data['trangThai'] ?? 'Chờ xử lý';
        final total = data['tongTien'] ?? 0;
        final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

        // Lấy thông tin sản phẩm đầu tiên để hiển thị ảnh demo
        final items = (data['items'] as List<dynamic>?);
        String firstItemName = "Đơn hàng";
        String firstItemImage = "";
        int totalItems = 0;

        if (items != null && items.isNotEmpty) {
          firstItemName = items[0]['ten'] ?? "Sản phẩm";
          firstItemImage = items[0]['anh'] ?? "";
          totalItems = items.length;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Đơn mua mới nhất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ảnh sản phẩm
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: firstItemImage.isNotEmpty
                            ? Image.network(
                          firstItemImage,
                          width: 60, height: 60, fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(color: Colors.grey[200], width: 60, height: 60, child: const Icon(Icons.image)),
                        )
                            : Container(color: Colors.green.shade50, width: 60, height: 60, child: const Icon(Icons.shopping_bag, color: Colors.green)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                      firstItemName,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Text(
                                      status,
                                      style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold)
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                                totalItems > 1 ? 'Và ${totalItems - 1} sản phẩm khác' : 'Số lượng: 1',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tổng tiền:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                Text(
                                    formatCurrency.format(total),
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Mã đơn: ${data['maDonHang'] ?? '...'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)
                      ),
                      // Kiểm tra Sync: Nếu isSync = false thì báo lỗi
                      if (data['isSync'] == false)
                        const Row(
                          children: [
                            Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text("Chờ đồng bộ", style: TextStyle(fontSize: 11, color: Colors.orange)),
                          ],
                        )
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Hủy')) return Colors.red;
    if (status.contains('Hoàn thành') || status.contains('Giao thành công')) return Colors.green;
    if (status.contains('Đang giao')) return Colors.blue;
    return Colors.orange; // Chờ xử lý, Chờ xác nhận...
  }

  Widget _buildMenuList(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.location_on_outlined, 'Địa chỉ giao hàng', isDarkMode),
          _buildMenuItem(Icons.confirmation_num_outlined, 'Ví Voucher / Điểm thưởng', isDarkMode),
          ListTile(
            leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.green),
            title: Text('Chế độ tối', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              activeColor: Colors.green,
            ),
          ),
          _buildMenuItem(Icons.help_outline, 'Trung tâm trợ giúp', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isDarkMode) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton(
      onPressed: () => _signOut(context),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 8),
          Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}