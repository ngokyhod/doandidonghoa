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

String _$adminTabHash() => r'5ca6e59fb557b2f6fadfe57ed38edd8b966afa74';

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
