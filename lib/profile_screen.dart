import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'theme_notifier.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;

  // Controllers and State for Edit Profile Tab
  final _formKey = GlobalKey<FormState>();
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

  // --- LOGIC FOR EDIT PROFILE ---
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
      final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${_user!.uid}.jpg');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _showMsg("Lỗi tải ảnh lên: $e", isError: true);
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null || !_formKey.currentState!.validate()) return;

    String? photoUrl;
    if (_imageFile != null) {
      photoUrl = await _uploadImage(_imageFile!);
      if (photoUrl == null) return; // Stop if upload fails
    }

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      final Map<String, dynamic> updatedData = {
        'fullName': _nameController.text,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
      };

      if (photoUrl != null) {
        updatedData['photoURL'] = photoUrl;
        await _user!.updatePhotoURL(photoUrl);
      }

      await userRef.update(updatedData);
      await _user!.updateDisplayName(_nameController.text);
      _showMsg("Cập nhật hồ sơ thành công!");
    } catch (e) {
      _showMsg("Lỗi cập nhật hồ sơ: $e", isError: true);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) context.go('/login');
    } catch (e) {
      _showMsg('Lỗi đăng xuất: $e', isError: true);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hồ Sơ Của Tôi'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.notifications_none), onPressed: () => context.push('/notifications')),
            IconButton(icon: const Icon(Icons.logout), onPressed: () => _signOut(context)),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3.0, // Make the indicator thicker
            labelColor: Colors.white, // Color for the selected tab
            unselectedLabelColor: Colors.white70, // Lighter color for unselected tabs
            tabs: [
              Tab(child: Text('Hồ Sơ', style: TextStyle(fontWeight: FontWeight.bold))),
              Tab(child: Text('Hoạt Động', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEditProfileTab(),
            _buildActivityTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileTab() {
    final themeMode = ref.watch(themeProvider);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        if (_nameController.text.isEmpty) _nameController.text = userData['fullName'] ?? _user!.displayName ?? '';
        if (_phoneController.text.isEmpty) _phoneController.text = userData['phoneNumber'] ?? '';
        if (_addressController.text.isEmpty) _addressController.text = userData['address'] ?? '';
        final String photoUrl = userData['photoURL'] ?? _user!.photoURL ?? '';

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green, width: 3)),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : (photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null) as ImageProvider?,
                          child: photoUrl.isEmpty && _imageFile == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      if (_isUploading) const Positioned.fill(child: Center(child: CircularProgressIndicator(color: Colors.white))),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Form Fields
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                ),
                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.save),
                    label: const Text("LƯU THAY ĐỔI", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                // Dark Mode Toggle
                AnimatedToggleSwitch<ThemeMode>.dual(
                  current: themeMode,
                  first: ThemeMode.light,
                  second: ThemeMode.dark,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                  styleBuilder: (value) => ToggleStyle(
                    backgroundColor: value == ThemeMode.light ? Colors.grey.shade200 : Colors.black,
                    indicatorColor: value == ThemeMode.light ? Colors.white : Colors.grey.shade800,
                    borderColor: Colors.transparent,
                  ),
                  iconBuilder: (value) => value == ThemeMode.light
                      ? const Icon(Icons.wb_sunny_rounded, color: Colors.orange)
                      : const Icon(Icons.brightness_3_rounded, color: Colors.yellow),
                  textBuilder: (value) => value == ThemeMode.light
                      ? const Center(child: Text('Light', style: TextStyle(fontWeight: FontWeight.bold)))
                      : const Center(child: Text('Dark', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  height: 50,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
         _buildActivityListItem(
          icon: Icons.favorite_border,
          title: 'Danh sách yêu thích',
          subtitle: 'Xem các sản phẩm bạn đã lưu',
          onTap: () => context.push('/wishlist'),
        ),
        _buildActivityListItem(
          icon: Icons.location_on_outlined,
          title: 'Sổ địa chỉ',
          subtitle: 'Quản lý địa chỉ giao hàng của bạn',
          onTap: () => context.push('/shipping_addresses'),
        ),
        _buildActivityListItem(
          icon: Icons.recycling,
          title: 'Yêu cầu thu gom của tôi',
          subtitle: 'Xem lại các yêu cầu đã gửi',
          onTap: () => context.push('/my_scrap_requests'),
        ),
        _buildActivityListItem(
          icon: Icons.shopping_basket_outlined,
          title: 'Đơn hàng đã mua',
          subtitle: 'Theo dõi và quản lý các đơn hàng',
          onTap: () => context.push('/my_orders'),
        ),
        _buildActivityListItem(
          icon: Icons.star_border,
          title: 'Đánh giá của tôi',
          subtitle: 'Xem các đánh giá bạn đã viết',
          onTap: () => context.push('/my_reviews'),
        ),
      ],
    );
  }

  Widget _buildActivityListItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(icon, color: Colors.green.shade600, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
