import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_api_service.dart';
import 'dart:async';

class AdminNotice {
  final String id; // ID của người dùng hoặc phòng chat
  final String title;
  final String subtitle;
  final int tabIndex;
  final DateTime time;
  AdminNotice({required this.id, required this.title, required this.subtitle, required this.tabIndex, required this.time});
}

final adminNotificationCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('chat_rooms')
      .where('unreadByAdmin', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final adminNoticeListProvider = StreamProvider<List<AdminNotice>>((ref) {
  final controller = StreamController<List<AdminNotice>>();

  void updateNotices() async {
    List<AdminNotice> notices = [];
    try {
      // 1. Lấy tin nhắn chưa đọc
      final chatSnapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('unreadByAdmin', isEqualTo: true)
          .get();

      for (var doc in chatSnapshot.docs) {
        final data = doc.data();
        notices.add(AdminNotice(
          id: doc.id,
          title: 'Tin nhắn từ ${data['userName'] ?? 'Khách hàng'}',
          subtitle: data['lastMessage'] ?? 'Bấm để trả lời',
          tabIndex: 4,
          time: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }

      // 2. Lấy Đơn hàng & Thu gom từ API
      final dashData = await AdminApiService.getDashboard();
      if (dashData != null) {
        int orders = (dashData['newOrdersThisWeek'] ?? dashData['NewOrdersThisWeek'] ?? 0).toInt();
        if (orders > 0) {
          notices.add(AdminNotice(
            id: 'orders',
            title: 'Có $orders đơn hàng mới',
            subtitle: 'Cần xác nhận ngay',
            tabIndex: 2,
            time: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      print("Lỗi thông báo: $e");
    }
    if (!controller.isClosed) controller.add(notices);
  }

  updateNotices();
  final sub = FirebaseFirestore.instance.collection('chat_rooms').snapshots().listen((_) => updateNotices());
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => updateNotices());

  ref.onDispose(() { sub.cancel(); timer.cancel(); controller.close(); });
  return controller.stream;
});
