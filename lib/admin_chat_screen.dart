
import 'package:flutter/material.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  // Dummy list of messages for UI purposes
  final List<Map<String, dynamic>> _messages = [
    {'sender': 'admin', 'text': 'Xin chào! Tôi có thể giúp gì cho bạn?'},
    {'sender': 'user', 'text': 'Tôi cần hỗ trợ về đơn hàng của mình.'},
    {'sender': 'admin', 'text': 'Vui lòng cung cấp mã đơn hàng của bạn.'},
  ];

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      // In a real app, you would send this to your backend/Firebase
      setState(() {
        _messages.add({'sender': 'user', 'text': _messageController.text});
        _messageController.clear();
      });
      // Simulate a reply from the admin
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages.add({'sender': 'admin', 'text': 'Cảm ơn bạn. Chúng tôi đang kiểm tra...'});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ trợ khách hàng'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final bool isUserMessage = message['sender'] == 'user';
                return Align(
                  alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: isUserMessage ? theme.primaryColor : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      message['text'],
                      style: TextStyle(color: isUserMessage ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildMessageComposer(theme),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: const [
          BoxShadow(offset: Offset(0, -1), blurRadius: 4, color: Colors.black12)
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Nhập tin nhắn...',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: theme.primaryColor),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
