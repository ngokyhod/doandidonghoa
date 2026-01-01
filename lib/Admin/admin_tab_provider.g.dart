// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_tab_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminTab)
const adminTabProvider = AdminTabProvider._();

final class AdminTabProvider extends $NotifierProvider<AdminTab, int> {
  const AdminTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminTabHash();

  @$internal
  @override
  AdminTab create() => AdminTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$adminTabHash() => r'89b6e1144ac721bce326c757ff4313ba09861ae4';

abstract class _$AdminTab extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(SelectedChatUser)
const selectedChatUserProvider = SelectedChatUserProvider._();

final class SelectedChatUserProvider
    extends $NotifierProvider<SelectedChatUser, String?> {
  const SelectedChatUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedChatUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedChatUserHash();

  @$internal
  @override
  SelectedChatUser create() => SelectedChatUser();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedChatUserHash() => r'04ce42455fab146d6338505c3967b7e5f1fa47d8';

abstract class _$SelectedChatUser extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
