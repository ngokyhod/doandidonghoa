import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Giữ lại nếu bạn dùng riverpod
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  File? _imageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- LOGIC XỬ LÝ ẢNH & UPDATE ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    if (_user == null) return null;
    setState(() => _isUploading = true);
    try {
      // Lưu ảnh vào thư mục profile_images/UID.jpg
      final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${_user!.uid}.jpg');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _showMsg("Lỗi tải ảnh: $e", isError: true);
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;

    setState(() => _isUploading = true);
    try {
      String? photoUrl;

      // 1. Nếu có chọn ảnh mới thì upload lên Storage trước
      if (_imageFile != null) {
        photoUrl = await _uploadImage(_imageFile!);
      }

      // 2. Cập nhật vào Firestore
      final userRef = FirebaseFirestore.instance.collection('users').doc(_user!.uid);

      final Map<String, dynamic> updatedData = {
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (photoUrl != null) {
        updatedData['photoURL'] = photoUrl;
        // Cập nhật cả bên Auth để hiển thị nhanh
        await _user!.updatePhotoURL(photoUrl);
      }
      if (_nameController.text.isNotEmpty) {
        await _user!.updateDisplayName(_nameController.text.trim());
      }

      // Dùng set với merge: true để nếu chưa có doc thì tạo mới, có rồi thì update
      await userRef.set(updatedData, SetOptions(merge: true));

      _showMsg("Cập nhật hồ sơ thành công!");
    } catch (e) {
      _showMsg("Lỗi cập nhật: $e", isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // GoRouter sẽ tự động chuyển về Login do logic ở main.dart
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Của Tôi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(context)
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lấy dữ liệu từ Firestore, nếu không có thì lấy tạm từ Auth
          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          // Chỉ điền vào controller nếu user chưa nhập gì (để tránh bị reset khi đang gõ)
          if (_nameController.text.isEmpty) {
            _nameController.text = userData['fullName'] ?? _user!.displayName ?? '';
          }
          if (_phoneController.text.isEmpty) {
            _phoneController.text = userData['phoneNumber'] ?? '';
          }
          if (_addressController.text.isEmpty) {
            _addressController.text = userData['address'] ?? '';
          }

          final String currentPhotoUrl = userData['photoURL'] ?? _user!.photoURL ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (currentPhotoUrl.isNotEmpty ? NetworkImage(currentPhotoUrl) : null) as ImageProvider?,
                        child: (currentPhotoUrl.isEmpty && _imageFile == null)
                            ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("LƯU THAY ĐỔI", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}