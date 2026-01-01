import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_tab_provider.g.dart';

@Riverpod(keepAlive: true)
class AdminTab extends _$AdminTab {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

// Provider mới để lưu trữ UID của khách hàng mà Admin đang chọn để chat
@Riverpod(keepAlive: true)
class SelectedChatUser extends _$SelectedChatUser {
  @override
  String? build() => null;

  void setSelectedUser(String uid) => state = uid;
}
