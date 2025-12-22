import 'dart:io'; // Để dùng File
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Để dùng XFile
import '../service/chat_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();

  // Danh sách tin nhắn
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Xin chào! Mình có thể giúp gì cho bạn hôm nay?', 'isUser': false}
  ];

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  bool _checkLogin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Yêu cầu đăng nhập"),
          content: const Text("Bạn cần đăng nhập để sử dụng tính năng Chatbot."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/login'); // Chuyển sang trang đăng nhập
              },
              child: const Text("Đăng nhập ngay"),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }
  // Gửi Text
  void _sendText() async {
    if (!_checkLogin()) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isLoading = true;
    });
    _controller.clear();

    String reply = await ChatService.sendMessage(text);

    setState(() {
      _messages.add({'text': reply, 'isUser': false});
      _isLoading = false;
    });
  }

  // Gửi Ảnh
  void _pickAndSendImage() async {
    // 1. Chọn ảnh (trả về XFile)
    if (!_checkLogin()) return;
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);

    if (photo != null) {
      setState(() {
        // 2. Lưu nguyên cục XFile vào list
        _messages.add({'image': photo, 'isUser': true});
        _isLoading = true;
      });

      // 3. Gửi XFile sang Service
      String reply = await ChatService.sendImage(photo);

      setState(() {
        _messages.add({'text': reply, 'isUser': false});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hỗ trợ trực tuyến", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Thường trả lời trong vài giây", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // KHUNG CHAT
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Hiển thị loading "Đang suy nghĩ..."
                if (index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 10),
                      child: Text("Đang suy nghĩ...", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                    ),
                  );
                }

                final msg = _messages[index];
                final isUser = msg['isUser'];

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(colors: [Color(0xFF0B84FF), Color(0xFF006EE6)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                          : null,
                      color: isUser ? null : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(0),
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(12),
                      ),
                    ),
                    // --- PHẦN QUAN TRỌNG ĐÃ SỬA ---
                    child: msg.containsKey('image')
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.network(
                        // Trên Web: Ép kiểu về XFile lấy path (blob URL)
                        (msg['image'] as XFile).path,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.white),
                      )
                          : Image.file(
                        // Trên Mobile: Ép kiểu về XFile lấy path, rồi tạo File (dart:io)
                        File((msg['image'] as XFile).path),
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Text(
                      msg['text'],
                      style: TextStyle(color: isUser ? Colors.white : const Color(0xFFE6EEF7)),
                    ),
                  ),
                );
              },
            ),
          ),

          // KHUNG NHẬP LIỆU
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.white70),
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Gõ tin nhắn...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF0B84FF)),
                  onPressed: _sendText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}