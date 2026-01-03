import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Admin/admin_tab_provider.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    // Sử dụng Consumer bọc bên trong build để tránh lỗi TypeError trên Web
    return Consumer(
      builder: (context, ref, child) {
        final isAdmin = _currentUser?.email?.toLowerCase() == 'phanthuky12@gmail.com';

        // Admin: lấy UID từ Provider. Khách: lấy UID của chính mình
        final String? targetUserId = isAdmin
            ? ref.watch(selectedChatUserProvider)
            : _currentUser?.uid;

        if (targetUserId == null) {
          return const Scaffold(body: Center(child: Text("Vui lòng chọn một khách hàng để hỗ trợ")));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6F9),
          appBar: AppBar(
            title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(targetUserId).snapshots(),
              builder: (context, snapshot) {
                final name = (snapshot.data?.data() as Map?)?['fullName'] ?? 'Đang tải...';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('Hỗ trợ trực tuyến', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                );
              },
            ),
            leading: isAdmin ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => ref.read(adminTabProvider.notifier).setTab(4), // Quay lại danh sách
            ) : null,
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessageList(targetUserId)),
              _buildInputArea(targetUserId, isAdmin),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList(String roomId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final messages = snapshot.data!.docs;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data() as Map<String, dynamic>;
            final isMe = data['senderId'] == _currentUser?.uid;
            return _buildMessageBubble(data['text'] ?? '', isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe ? Colors.green.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildInputArea(String roomId, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.green),
              onPressed: () => _sendMessage(roomId, isAdmin),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String roomId, bool isAdmin) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // 1. Gửi tin nhắn vào messages
    await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).collection('messages').add({
      'text': text,
      'senderId': _currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Cập nhật phòng chat và BẬT CHUÔNG CHO ADMIN (nếu khách gửi)
    await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadByAdmin': !isAdmin, // Khách gửi -> true (Chuông reo), Admin gửi -> false (Chuông tắt)
    }, SetOptions(merge: true));
  }
}
