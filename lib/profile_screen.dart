import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme_notifier.dart';

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

    // --- SỬA LỖI Ở ĐÂY: Đổi themeNotifierProvider thành themeProvider ---
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    // -------------------------------------------------------------------

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
          final String phone = userData['phoneNumber'] ?? '0912 345 678';
          final String photoUrl = userData['photoURL'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(name, phone, photoUrl, isDarkMode),
                const SizedBox(height: 20),
                _buildMyOrdersSection(isDarkMode),
                const SizedBox(height: 20),
                _buildNewestOrderCard(isDarkMode),
                const SizedBox(height: 20),
                // Truyền isDarkMode vào danh sách menu để dùng cho nút gạt
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

  // ... (Các widget _buildProfileHeader, _buildMyOrdersSection... giữ nguyên như cũ)

  Widget _buildProfileHeader(String name, String phone, String photoUrl, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.blue.shade100, width: 2),
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
                  child: const Text('Thành viên Bạc', style: TextStyle(color: Colors.green, fontSize: 12)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.grey),
            onPressed: () {},
          )
        ],
      ),
    );
  }

  Widget _buildMyOrdersSection(bool isDarkMode) {
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
              Text('Đơn hàng của tôi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
              TextButton(
                onPressed: () {},
                child: const Text('Xem lịch sử >', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderStatusItem(Icons.assignment_outlined, 'Chờ xác nhận', isDarkMode, badgeCount: 2),
              _buildOrderStatusItem(Icons.sync_outlined, 'Đang xử lý', isDarkMode),
              _buildOrderStatusItem(Icons.local_shipping_outlined, 'Đang giao', isDarkMode, badgeCount: 1),
              _buildOrderStatusItem(Icons.star_outline, 'Đánh giá', isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusItem(IconData icon, String label, bool isDarkMode, {int badgeCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Icon(icon, size: 28, color: isDarkMode ? Colors.white70 : Colors.black87),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white54 : Colors.black54)),
          ],
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildNewestOrderCard(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Đơn hàng mới nhất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://picsum.photos/100',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], width: 60, height: 60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Bông xơ tự nhiên', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.shade50.withOpacity(isDarkMode ? 0.1 : 1), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Đang giao', style: TextStyle(color: Colors.green, fontSize: 10)),
                            ),
                          ],
                        ),
                        const Text('(Loại 1) - 50kg', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const Text('Phân loại: Bao 50kg', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('x1', style: TextStyle(color: Colors.grey)),
                            Text('1.250.000đ', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
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
                  const Text('Đơn hàng: #DH-1234', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                      foregroundColor: isDarkMode ? Colors.white70 : Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('Theo dõi đơn', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
          _buildMenuItem(Icons.account_balance_wallet_outlined, 'Phương thức thanh toán', isDarkMode),
          _buildMenuItem(Icons.confirmation_num_outlined, 'Ví Voucher / Điểm thưởng', isDarkMode),
          _buildMenuItem(Icons.lock_outline, 'Đổi mật khẩu', isDarkMode),
          // Toggle Switch cho chế độ tối
          ListTile(
            leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.green),
            title: Text('Chế độ tối', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                // --- SỬA LỖI Ở ĐÂY: Đổi themeNotifierProvider thành themeProvider ---
                ref.read(themeProvider.notifier).toggleTheme();
                // -------------------------------------------------------------------
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 8),
          Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}