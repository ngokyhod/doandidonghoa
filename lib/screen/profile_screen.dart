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
  Future<void> _showAddressDialog() async {
    // 1. Lấy dữ liệu cũ từ Firestore lên để điền sẵn vào ô nhập
    final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    final data = doc.data() ?? {};

    final nameCtrl = TextEditingController(text: data['fullName'] ?? _user!.displayName ?? '');
    final phoneCtrl = TextEditingController(text: data['phoneNumber'] ?? '');
    final addressCtrl = TextEditingController(text: data['address'] ?? ''); // Thêm trường address vào Firebase

    final isDarkMode = ref.read(themeProvider) == ThemeMode.dark;

    if (!mounted) return;

    // 2. Hiển thị Dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Địa chỉ nhận hàng mặc định', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Họ và tên", prefixIcon: Icon(Icons.person, color: Colors.green)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Số điện thoại", prefixIcon: Icon(Icons.phone, color: Colors.green)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Địa chỉ chi tiết", prefixIcon: Icon(Icons.location_on, color: Colors.green)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                // 3. Lưu thông tin vào Firestore
                await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
                  'fullName': nameCtrl.text.trim(),
                  'phoneNumber': phoneCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                }, SetOptions(merge: true));

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu địa chỉ thành công!'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Lưu thông tin'),
            ),
          ],
        );
      },
    );
  }
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

  // --- HÀM MỞ POPUP LIÊN HỆ HỖ TRỢ ---
  void _showSupportDialog() {
    final isDarkMode = ref.read(themeProvider) == ThemeMode.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.support_agent, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text('Liên hệ hỗ trợ', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nếu bạn gặp vấn đề về đơn hàng hoặc ứng dụng, vui lòng liên hệ với chúng tôi qua:',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14)),
              const SizedBox(height: 16),
              _buildContactLine(Icons.phone, 'Hotline: 1900 1234', isDarkMode),
              const SizedBox(height: 8),
              _buildContactLine(Icons.email, 'Email: support@nongsan.com', isDarkMode),
              const SizedBox(height: 8),
              _buildContactLine(Icons.chat_bubble_outline, 'Mở tính năng Trợ lý AI để chat trực tiếp', isDarkMode),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactLine(IconData icon, String text, bool isDarkMode) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
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

                // --- PHẦN 2: ĐƠN HÀNG MỚI NHẤT ---
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

  Widget _buildOrderStatsSection(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('DonHang').where('uid', isEqualTo: _user!.uid).snapshots(),
      builder: (context, orderSnapshot) {
        return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ThuGom').where('uid', isEqualTo: _user!.uid).snapshots(),
            builder: (context, scrapSnapshot) {

              int pendingCount = 0;
              int scrapCount = 0;

              if (orderSnapshot.hasData) {
                final orders = orderSnapshot.data!.docs;
                pendingCount = orders.where((d) {
                  final st = (d.data() as Map)['trangThai'] ?? '';
                  // Đơn mua bao gồm cả đơn đang chờ và đang giao để khách theo dõi chung
                  return st != 'Hoàn thành' && st != 'Đã hủy';
                }).length;
              }

              if (scrapSnapshot.hasData) {
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
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Dùng spaceEvenly cho 2 nút
                      children: [
                        _buildOrderStatusItem(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Đơn mua',
                          isDarkMode: isDarkMode,
                          badgeCount: pendingCount,
                          onTap: () => context.push('/my_orders_screen'),
                        ),
                        _buildOrderStatusItem(
                          icon: Icons.recycling,
                          label: 'Thu gom',
                          isDarkMode: isDarkMode,
                          badgeCount: scrapCount,
                          onTap: () => context.push('/my-scrap-requests_screen'),
                        ),
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

  Widget _buildOrderStatusItem({required IconData icon, required String label, required bool isDarkMode, int badgeCount = 0, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: isDarkMode ? Colors.white70 : Colors.green.shade700),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
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
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white54 : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildNewestOrderCard(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('DonHang')
          .where('uid', isEqualTo: _user!.uid)
          .orderBy('ngayDat', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        final status = data['trangThai'] ?? 'Chờ xử lý';
        final total = data['tongTien'] ?? 0;
        final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

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
    return Colors.orange;
  }

  Widget _buildMenuList(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.location_on_outlined, 'Địa chỉ giao hàng', isDarkMode, onTap: _showAddressDialog),
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
          // Thay Trung tâm trợ giúp bằng Popup Liên hệ
          _buildMenuItem(Icons.headset_mic_outlined, 'Liên hệ hỗ trợ', isDarkMode, onTap: _showSupportDialog),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isDarkMode, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
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