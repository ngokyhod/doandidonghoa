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

    return Consumer(
      builder: (context, ref, child) {
        final String currentEmail = _currentUser?.email?.trim().toLowerCase() ?? '';
        final bool isAdmin = currentEmail == 'phanthuky12@gmail.com';

        final String? roomId = isAdmin
            ? ref.watch(selectedChatUserProvider)
            : _currentUser?.uid;

        if (roomId == null) {
          return const Scaffold(body: Center(child: Text("Vui lòng chọn một khách hàng để hỗ trợ")));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6F9),
          appBar: AppBar(
            title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(roomId).snapshots(),
              builder: (context, snapshot) {
                final name = (snapshot.data?.data() as Map?)?['fullName'] ?? 'Hỗ trợ khách hàng';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('Trực tuyến', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                );
              },
            ),
            leading: isAdmin ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => ref.read(adminTabProvider.notifier).setTab(4),
            ) : null,
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessageList(roomId)),
              _buildInputArea(roomId, isAdmin),
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
        if (snapshot.hasError) return const Center(child: Text('Lỗi tải tin nhắn'));
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

  // --- SỬA PHẦN NÀY ĐỂ TRÁNH BỊ CHATBOT ĐÈ ---
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                minLines: 1,
                maxLines: 3, // Cho phép nhập nhiều dòng
              ),
            ),
            const SizedBox(width: 8),

            // Nút gửi tin nhắn
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () => _sendMessage(roomId, isAdmin),
              ),
            ),

            // --- QUAN TRỌNG: Thêm khoảng trống 70px bên phải để né nút Chatbot ---
            const SizedBox(width: 70),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String roomId, bool isAdmin) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // 1. Gửi tin nhắn
    await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).collection('messages').add({
      'text': text,
      'senderId': _currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Cập nhật trạng thái phòng chat
    await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadByAdmin': !isAdmin,
    }, SetOptions(merge: true));
  }
}