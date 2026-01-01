import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_api_service.dart';
import 'dart:async';

// Model thông báo gọn nhẹ
class AdminNotice {
  final String title;
  final String subtitle;
  final int tabIndex;
  final DateTime time;
  AdminNotice({required this.title, required this.subtitle, required this.tabIndex, required this.time});
}

// 1. PROVIDER ĐẾM SỐ LƯỢNG (DÙNG CHO CÁI CHUÔNG)
final adminNotificationCountProvider = StreamProvider<int>((ref) {
  // Lắng nghe tin nhắn chưa đọc từ chat_rooms
  return FirebaseFirestore.instance
      .collection('chat_rooms')
      .where('unreadByAdmin', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// 2. PROVIDER DANH SÁCH CHI TIẾT (DÙNG CHO PANEL KHI BẤM VÀO CHUÔNG)
final adminNoticeListProvider = StreamProvider<List<AdminNotice>>((ref) {
  final controller = StreamController<List<AdminNotice>>();

  // Hàm cập nhật danh sách tổng hợp
  void updateNotices() async {
    List<AdminNotice> notices = [];

    try {
      // A. Lấy tin nhắn từ Firestore
      final chatSnapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('unreadByAdmin', isEqualTo: true)
          .get();
      
      for (var doc in chatSnapshot.docs) {
        notices.add(AdminNotice(
          title: 'Tin nhắn từ ${doc['userName']}',
          subtitle: doc['lastMessage'] ?? 'Bấm để trả lời',
          tabIndex: 4,
          time: (doc['lastMessageTime'] as Timestamp).toDate(),
        ));
      }

      // B. Lấy Đơn hàng & Thu gom từ API (Cập nhật 30s/lần)
      final dashData = await AdminApiService.getDashboard();
      if (dashData != null) {
        int orders = (dashData['newOrdersThisWeek'] ?? dashData['NewOrdersThisWeek'] ?? 0).toInt();
        int collections = (dashData['pendingCollectionRequests'] ?? dashData['PendingCollectionRequests'] ?? 0).toInt();

        if (orders > 0) {
          notices.add(AdminNotice(
            title: 'Có $orders đơn hàng mới',
            subtitle: 'Bấm để duyệt đơn',
            tabIndex: 2,
            time: DateTime.now(),
          ));
        }
        if (collections > 0) {
          notices.add(AdminNotice(
            title: 'Có $collections yêu cầu thu gom',
            subtitle: 'Bấm để điều phối kho',
            tabIndex: 3,
            time: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      print("Lỗi tổng hợp thông báo: $e");
    }

    if (!controller.isClosed) controller.add(notices);
  }

  // Chạy lần đầu
  updateNotices();

  // Lắng nghe Firestore để cập nhật lại danh sách ngay lập tức khi có tin mới
  final sub = FirebaseFirestore.instance.collection('chat_rooms').snapshots().listen((_) => updateNotices());

  // Định kỳ cập nhật từ API sau mỗi 30 giây (cho đơn hàng/thu gom)
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => updateNotices());

  ref.onDispose(() {
    sub.cancel();
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
