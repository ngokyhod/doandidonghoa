import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_notifier.dart';
import 'admin_tab_provider.dart';
import 'admin_api_service.dart'; // IMPORT API SERVICE

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> with SingleTickerProviderStateMixin {
  TabController? _innerTabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    _innerTabController ??= TabController(length: 2, vsync: this);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F6F9),
      appBar: AppBar(
        title: Text('Khách hàng & Hỗ trợ', 
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18)),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _innerTabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Danh sách khách'),
            Tab(text: 'Tin nhắn hỗ trợ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _innerTabController,
        children: [
          _buildUserListTab(isDarkMode, cardColor, textColor),
          _buildChatRoomsTab(isDarkMode, cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildUserListTab(bool isDarkMode, Color cardColor, Color textColor) {
    return Column(
      children: [
        _buildSearchBox(isDarkMode, cardColor, textColor),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final users = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['fullName'] ?? '').toString().toLowerCase().contains(_searchQuery);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final data = users[index].data() as Map<String, dynamic>;
                  final uid = users[index].id;
                  return _buildUserCard(uid, data, isDarkMode, cardColor, textColor);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatRoomsTab(bool isDarkMode, Color cardColor, Color textColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chat_rooms')
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final rooms = snapshot.data!.docs;

        if (rooms.isEmpty) return const Center(child: Text('Chưa có tin nhắn nào'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final doc = rooms[index];
            final room = doc.data() as Map<String, dynamic>;
            final String userId = room['userId'] ?? doc.id;
            final bool unread = room['unreadByAdmin'] == true;

            return Card(
              color: cardColor,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                onTap: () {
                  ref.read(selectedChatUserProvider.notifier).setSelectedUser(userId);
                  ref.read(adminTabProvider.notifier).setTab(5);
                  FirebaseFirestore.instance.collection('chat_rooms').doc(userId).update({'unreadByAdmin': false});
                },
                leading: Badge(
                  showBadge: unread,
                  child: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.chat, color: Colors.white)),
                ),
                title: Text(room['userName'] ?? 'Khách hàng', style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal, color: textColor)),
                subtitle: Text(room['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, size: 16),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard(String uid, Map<String, dynamic> user, bool isDarkMode, Color cardColor, Color textColor) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user['photoURL'] != null && user['photoURL'] != '' ? NetworkImage(user['photoURL']) : null,
          child: (user['photoURL'] == null || user['photoURL'] == '') ? const Icon(Icons.person) : null,
        ),
        title: Text(user['fullName'] ?? 'N/A', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        subtitle: Text(user['email'] ?? 'N/A', style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_outlined, color: Colors.blue, size: 20),
              onPressed: () {
                ref.read(selectedChatUserProvider.notifier).setSelectedUser(uid);
                ref.read(adminTabProvider.notifier).setTab(5);
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () => _showUserOptions(context, uid, user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox(bool isDarkMode, Color cardColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Tìm khách hàng...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  void _showUserOptions(BuildContext context, String uid, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.sync, color: Colors.blue),
            title: const Text('Đồng bộ sang SQL Server'),
            onTap: () async {
              Navigator.pop(context);
              bool success = await AdminApiService.syncUserUpdate(user);
              _showSnackBar(success ? "Đồng bộ thành công" : "Lỗi đồng bộ");
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Khóa tài khoản', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              bool success = await AdminApiService.blockUser(uid);
              _showSnackBar(success ? "Đã khóa tài khoản trên Server" : "Lỗi khi khóa");
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class Badge extends StatelessWidget {
  final Widget child;
  final bool showBadge;
  const Badge({super.key, required this.child, this.showBadge = false});
  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;
    return Stack(children: [child, Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)))]);
  }
}
