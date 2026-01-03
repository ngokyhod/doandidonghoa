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
        final isAdmin = _currentUser?.email?.toLowerCase() == 'phanthuky12@gmail.com';

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
              onPressed: () => ref.read(adminTabProvider.notifier).setTab(4),
            ) : null,
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessageList(targetUserId)),
              // Truyền isAdmin để xử lý logic gửi tin
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

        // Tự động cuộn xuống cuối khi có tin nhắn mới
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16), // Padding chung
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // Giới hạn chiều rộng tin nhắn
        decoration: BoxDecoration(
          color: isMe ? Colors.green.shade600 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildInputArea(String roomId, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send, // Hiển thị nút Gửi trên bàn phím
                onSubmitted: (_) => _sendMessage(roomId, isAdmin), // Nhấn Enter là gửi
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
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

            // --- QUAN TRỌNG: KHOẢNG TRỐNG ĐỂ TRÁNH NÚT CHATBOT ---
            // Nếu bạn có nút Chatbot ở góc phải dưới, đoạn này sẽ đẩy vùng nhập liệu sang trái
            // để nút Gửi không bị che.
            const SizedBox(width: 70), // Khoảng 70px cho nút Chatbot của AppShell
          ],
        ),
      ),
    );
  }

  void _sendMessage(String roomId, bool isAdmin) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    try {
      // 1. Gửi tin nhắn vào messages
      await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).collection('messages').add({
        'text': text,
        'senderId': _currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Cập nhật phòng chat
      await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadByAdmin': !isAdmin,
      }, SetOptions(merge: true));
    } catch (e) {
      // Xử lý lỗi nếu cần
      print("Lỗi gửi tin nhắn: $e");
    }
  }
}