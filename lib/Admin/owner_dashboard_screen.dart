import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_api_service.dart';
import 'package:intl/intl.dart';
import '../theme_notifier.dart';
import 'admin_tab_provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/admin_notification_provider.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final data = await AdminApiService.getDashboard();
    if (mounted) {
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final Color mainTextColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.white70 : Colors.grey.shade800;
    
    // Lắng nghe thông báo real-time
    final notificationCount = ref.watch(adminNotificationCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.grey),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saika Hana', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Admin Dashboard', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.grey), 
                onPressed: () => ref.read(adminTabProvider.notifier).setTab(4),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$notificationCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn thoát khỏi quyền Admin?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                    TextButton(onPressed: _handleLogout, child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
          ),
          const CircleAvatar(radius: 15, backgroundColor: Colors.green, child: Text('O', style: TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xin chào,', style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(_currentUser?.email ?? 'Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mainTextColor)),
                    const SizedBox(height: 20),
                    
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          'Doanh thu (Tháng)',
                          currencyFormat.format(_dashboardData?['monthlyRevenue'] ?? 0),
                          Icons.account_balance_wallet,
                          Colors.green,
                          isDarkMode,
                          onTap: () {},
                          trend: '+12%',
                        ),
                        _buildStatCard(
                          'Đơn hàng mới',
                          '${_dashboardData?['newOrdersThisWeek'] ?? 0}',
                          Icons.shopping_cart,
                          Colors.blue,
                          isDarkMode,
                          onTap: () => ref.read(adminTabProvider.notifier).setTab(2),
                        ),
                        _buildStatCard(
                          'Người dùng mới',
                          '${_dashboardData?['newUsersThisMonth'] ?? 0}',
                          Icons.people,
                          Colors.purple,
                          isDarkMode,
                          onTap: () => ref.read(adminTabProvider.notifier).setTab(4),
                        ),
                        _buildStatCard(
                          'YC Thu gom chờ',
                          '${_dashboardData?['pendingCollectionRequests'] ?? 0}',
                          Icons.recycling,
                          Colors.orange,
                          isDarkMode,
                          onTap: () => ref.read(adminTabProvider.notifier).setTab(3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Text('QUẢN LÝ NHANH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: mainTextColor, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    _buildQuickAction(Icons.inventory_2, 'Quản lý Sản phẩm', 'Thêm, sửa, xóa sản phẩm...', () => ref.read(adminTabProvider.notifier).setTab(1), isDarkMode, mainTextColor, subTextColor),
                    _buildQuickAction(Icons.receipt_long, 'Quản lý Đơn hàng', 'Xác nhận, hủy, theo dõi đơn...', () => ref.read(adminTabProvider.notifier).setTab(2), isDarkMode, mainTextColor, subTextColor),
                    _buildQuickAction(Icons.people_alt, 'Quản lý Khách hàng', 'Xem danh sách & Chat hỗ trợ...', () => ref.read(adminTabProvider.notifier).setTab(4), isDarkMode, mainTextColor, subTextColor),
                    _buildQuickAction(Icons.warehouse, 'Thu gom Phụ phẩm', 'Lịch trình & yêu cầu thu gom...', () => ref.read(adminTabProvider.notifier).setTab(3), isDarkMode, mainTextColor, subTextColor),
                    
                    const SizedBox(height: 24),
                    _buildRevenueChart(isDarkMode, mainTextColor, subTextColor),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDarkMode, {required VoidCallback onTap, String? trend}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (trend != null)
                  Text(trend, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
            Text(title, style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String title, String sub, VoidCallback onTap, bool isDarkMode, Color mainTextColor, Color subTextColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.green.shade700),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: mainTextColor)),
        subtitle: Text(sub, style: TextStyle(fontSize: 11, color: subTextColor)),
        trailing: Icon(Icons.chevron_right, size: 20, color: subTextColor),
      ),
    );
  }

  Widget _buildRevenueChart(bool isDarkMode, Color mainTextColor, Color subTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Biểu đồ Doanh thu', style: TextStyle(fontWeight: FontWeight.bold, color: mainTextColor)),
              Text('7 ngày qua', style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 150,
            width: double.infinity,
            child: CustomPaint(painter: _DashboardChartPainter(Colors.green)),
          ),
        ],
      ),
    );
  }
}

class _DashboardChartPainter extends CustomPainter {
  final Color color;
  _DashboardChartPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(0, size.height * 0.1);
    path.lineTo(size.width * 0.2, size.height * 0.8);
    path.lineTo(size.width * 0.4, size.height * 0.8);
    path.lineTo(size.width * 0.6, size.height * 0.8);
    path.lineTo(size.width * 0.8, size.height * 0.8);
    path.lineTo(size.width, size.height * 0.8);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
