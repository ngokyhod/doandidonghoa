import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // ĐÃ THÊM THƯ VIỆN MARKDOWN
import '../service/chat_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Xin chào! Tôi có thể giúp gì cho bạn về thông tin nông sản và phụ phẩm hôm nay? Bạn cũng có thể tải ảnh lên để tôi nhận diện.',
      'isUser': false
    }
  ];

  bool _isLoading = false;
  XFile? _selectedImagePreview;

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
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context);
                context.push('/login');
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

  void _pickImage() async {
    if (!_checkLogin()) return;
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        _selectedImagePreview = photo;
      });
    }
  }

  void _clearPreviewImage() {
    setState(() {
      _selectedImagePreview = null;
    });
  }

  // ĐÃ SỬA: Lắng nghe Stream để cập nhật từng chữ
  void _handleSend() async {
    if (!_checkLogin()) return;

    final text = _controller.text.trim();
    final imageToSend = _selectedImagePreview;

    if (text.isEmpty && imageToSend == null) return;

    // 1. In tin nhắn của User
    setState(() {
      _messages.add({
        'text': text.isNotEmpty ? text : null,
        'image': imageToSend,
        'isUser': true
      });
      _isLoading = true; // Hiện "AI đang gõ..."
      _controller.clear();
      _selectedImagePreview = null;
    });

    // 2. Tạo sẵn bong bóng chat rỗng cho AI
    int aiMsgIndex = _messages.length;
    setState(() {
      _messages.add({'text': '', 'isUser': false});
      _isLoading = false;
    });

    String fullReply = "";

    try {
      // 3. Lắng nghe Stream và ghép chữ vào
      await for (String chunk in ChatService.sendMessageStream(text, image: imageToSend)) {
        fullReply += chunk;
        if (mounted) {
          setState(() {
            _messages[aiMsgIndex]['text'] = fullReply;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (fullReply.isEmpty) {
            _messages[aiMsgIndex]['text'] = "Lỗi kết nối: $e";
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Trợ lý AI Nông nghiệp", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text("Llama 3 + Vision", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(left: 24, bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("AI đang gõ...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
              ),
            ),

          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedImagePreview != null)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(_selectedImagePreview!.path, height: 80, width: 80, fit: BoxFit.cover)
                              : Image.file(File(_selectedImagePreview!.path), height: 80, width: 80, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: GestureDetector(
                          onTap: _clearPreviewImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined, color: Colors.grey),
                      onPressed: _pickImage,
                      tooltip: "Đính kèm ảnh",
                    ),

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC4C7C5)),
                        ),
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.black87),
                          decoration: const InputDecoration(
                            hintText: "Nhập câu hỏi hoặc đính kèm ảnh...",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF10A37F),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: _handleSend,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final bool isUser = msg['isUser'];
    final String? text = msg['text'];
    final XFile? image = msg['image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF10A37F),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFE9EEF6) : Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (image != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(image.path, width: 200, fit: BoxFit.cover)
                            : Image.file(File(image.path), width: 200, fit: BoxFit.cover),
                      ),
                    ),

                  // ĐÃ SỬA: SỬ DỤNG MARKDOWN CHO AI, TEXT THƯỜNG CHO USER
                  if (text != null && text.isNotEmpty)
                    !isUser
                        ? MarkdownBody(
                      data: text
                          .replaceAll(RegExp(r"<div[^>]*>"), "_")
                          .replaceAll("</div>", "_\n\n")
                          .replaceAll(RegExp(r"<br\s*/?>"), "\n"),
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 15, height: 1.5),
                        strong: const TextStyle(color: Color(0xFF1F1F1F), fontWeight: FontWeight.bold),
                        em: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    )
                        : Text(
                      text,
                      style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 15, height: 1.5),
                    ),
                ],
              ),
            ),
          ),

          if (!isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }
}