import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_tab_provider.g.dart';

@Riverpod(keepAlive: true)
class AdminTab extends _$AdminTab {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}
