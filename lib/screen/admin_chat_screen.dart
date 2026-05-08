import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:image_picker/image_picker.dart';
import '../Admin/admin_tab_provider.dart';

// 🔴 CLASS MỚI: BỎ QUA LỖI CHỨNG CHỈ BẢO MẬT SSL KHI DÙNG HTTPS LOCALHOST
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  HubConnection? _hubConnection;
  List<Map<String, dynamic>> _messages = [];
  bool _isConnected = false;
  bool _isUploading = false;

  late bool isAdmin;
  late String? roomId;
  XFile? _selectedImagePreview;

  // IP MÁY CHỦ
  final String serverBaseUrl = kIsWeb ? 'https://localhost:7240' : 'https://10.0.2.2:7240';

  @override
  void initState() {
    super.initState();

    // 🔴 ÁP DỤNG CLASS VƯỢT RÀO BẢO MẬT LÊN TOÀN BỘ APP
    HttpOverrides.global = _DevHttpOverrides();

    final String currentEmail = _currentUser?.email?.trim().toLowerCase() ?? '';
    isAdmin = currentEmail == 'phanthuky12@gmail.com';

    _initSignalR();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final targetUid = isAdmin ? roomId : _currentUser?.uid;
    if (targetUid == null || targetUid.isEmpty) return;

    final url = Uri.parse('$serverBaseUrl/api/MobileApi/history/$targetUid');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _messages = data.map((m) {
            bool isFromAdmin = m['isFromAdmin'] ?? false;
            return {
              'text': m['message'] ?? '',
              'imageUrl': m['imageUrl'],
              'senderId': isFromAdmin ? 'Admin' : targetUid,
              'time': m['sentTime']
            };
          }).toList();
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Lỗi tải lịch sử tin nhắn: $e");
    }
  }

  void _initSignalR() async {
    String hubUrl = '$serverBaseUrl/Hubs/ChatHub';

    _hubConnection = HubConnectionBuilder().withUrl(hubUrl).build();
    _hubConnection?.on("ReceiveUserMessage", _handleIncomingMessage);
    _hubConnection?.on("ReceiveAdminReply", _handleIncomingMessage);
    _hubConnection?.on("AdminSentMessage", _handleIncomingMessage);

    try {
      await _hubConnection?.start();
      setState(() => _isConnected = true);

      if (isAdmin) {
        await _hubConnection?.invoke("RegisterMobileAdmin", args: []);
      } else {
        await _hubConnection?.invoke("RegisterMobileUser", args: [_currentUser?.uid ?? ""]);
      }
    } catch (e) {
      print("Lỗi kết nối SignalR: $e");
    }
  }

  void _handleIncomingMessage(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = args[0] as Map<String, dynamic>;
      String msgSenderId = data['senderId']?.toString() ?? 'Admin';

      if (!isAdmin || msgSenderId == roomId || msgSenderId == 'Admin') {
        setState(() {
          _messages.add({
            'text': data['message'] ?? '',
            'imageUrl': data['imageUrl'],
            'senderId': msgSenderId,
            'time': data['sentTime']
          });
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        _selectedImagePreview = photo;
      });
    }
  }

  Future<String?> _uploadImageToCSharp(XFile file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$serverBaseUrl/api/MobileApi/upload'));

      // 🔴 ĐÃ SỬA LỖI Ở ĐÂY: Đọc ảnh thành dạng Byte thay vì dùng đường dẫn Path vật lý
      final bytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name, // Giữ nguyên tên gốc của bức ảnh
      );

      request.files.add(multipartFile);

      request.fields['senderId'] = _currentUser?.uid ?? "MobileClient";
      request.fields['receiverId'] = "Admin";
      request.fields['senderName'] = _currentUser?.displayName ?? "Khách hàng Mobile";
      request.fields['isFromAdmin'] = "false";

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        return json['imageUrl'];
      } else {
        print("Server từ chối: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Lỗi CATCH cực mạnh tại Mobile: $e");
    }
    return null;
  }

  void _sendMessage(String roomId, bool isAdmin) async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImagePreview == null) return;
    if (!_isConnected) return;

    setState(() => _isUploading = true);

    String uploadedImageUrl = "";

    // 1. XỬ LÝ UPLOAD ẢNH (BẮT LỖI NGHIÊM NGẶT)
    if (_selectedImagePreview != null) {
      final url = await _uploadImageToCSharp(_selectedImagePreview!);
      if (url != null) {
        uploadedImageUrl = url;
      } else {
        // 🔴 NẾU UPLOAD LỖI: Dừng lại ngay! Hiện thông báo đỏ, KHÔNG XÓA ẢNH
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lỗi tải ảnh lên máy chủ! Vui lòng kiểm tra lại kết nối mạng."),
              backgroundColor: Colors.red,
            )
        );
        return;
      }
    }

    // 2. CHỈ XÓA KHUNG CHAT KHI MỌI THỨ ĐÃ THÀNH CÔNG
    _controller.clear();
    setState(() {
      _selectedImagePreview = null;
      _isUploading = false;
    });

    try {
      if (isAdmin) {
        await _hubConnection?.invoke("SendReplyToUser", args: [roomId, text, uploadedImageUrl]);
      } else {
        final userName = _currentUser?.displayName ?? _currentUser?.email ?? "Khách hàng Mobile";
        final safeUid = _currentUser?.uid ?? "";
        await _hubConnection?.invoke("SendMessageFromMobile", args: [safeUid, userName, text, uploadedImageUrl]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi gửi SignalR: $e")));
    }
  }

  @override
  void dispose() {
    _hubConnection?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return Consumer(
      builder: (context, ref, child) {
        roomId = isAdmin ? ref.watch(selectedChatUserProvider) : _currentUser?.uid;

        if (roomId == null) return const Scaffold(body: Center(child: Text("Vui lòng chọn khách hàng")));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6F9),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAdmin ? "Mã khách: ${roomId!.substring(0, 5)}..." : "Hỗ trợ khách hàng", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_isConnected ? 'Đã kết nối máy chủ SQL' : 'Đang kết nối API...', style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessageList()),
              _buildInputArea(roomId!, isAdmin),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) return const Center(child: Text("Hãy bắt đầu trò chuyện", style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final data = _messages[index];
        final isMe = (isAdmin && data['senderId'] == 'Admin') || (!isAdmin && data['senderId'] != 'Admin');
        return _buildMessageBubble(data, isMe);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final String? text = msg['text'];
    String? imgUrl = msg['imageUrl'];

    if (imgUrl != null && imgUrl.isNotEmpty && imgUrl.startsWith('/')) {
      imgUrl = '$serverBaseUrl$imgUrl';
    }

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
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (imgUrl != null && imgUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imgUrl,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            if (text != null && text.isNotEmpty)
              Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(String roomId, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedImagePreview != null)
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.network(_selectedImagePreview!.path, height: 80, width: 80, fit: BoxFit.cover)
                          : Image.file(File(_selectedImagePreview!.path), height: 80, width: 80, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: -5, top: -5,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImagePreview = null),
                      child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                    ),
                  )
                ],
              ),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.grey),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _isUploading ? 'Đang gửi ảnh...' : 'Nhập tin nhắn...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isUploading
                    ? const CircularProgressIndicator()
                    : IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () => _sendMessage(roomId, isAdmin),
                ),
                const SizedBox(width: 70),
              ],
            ),
          ],
        ),
      ),
    );
  }
}