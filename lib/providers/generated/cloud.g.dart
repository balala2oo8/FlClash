// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../cloud.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in account, restored from preferences and kept across launches.

@ProviderFor(CloudAuth)
final cloudAuthProvider = CloudAuthProvider._();

/// The signed-in account, restored from preferences and kept across launches.
final class CloudAuthProvider
    extends $NotifierProvider<CloudAuth, CloudSession?> {
  /// The signed-in account, restored from preferences and kept across launches.
  CloudAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudAuthHash();

  @$internal
  @override
  CloudAuth create() => CloudAuth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudSession?>(value),
    );
  }
}

String _$cloudAuthHash() => r'7d62d43997e64bbc33fce805c696c8c2fab75207';

/// The signed-in account, restored from preferences and kept across launches.

abstract class _$CloudAuth extends $Notifier<CloudSession?> {
  CloudSession? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CloudSession?, CloudSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CloudSession?, CloudSession?>,
              CloudSession?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The synced profile is read-only in the UI; membership is account-bound and
/// never stored on the profile itself.

@ProviderFor(isCloudProfile)
final isCloudProfileProvider = IsCloudProfileFamily._();

/// The synced profile is read-only in the UI; membership is account-bound and
/// never stored on the profile itself.

final class IsCloudProfileProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// The synced profile is read-only in the UI; membership is account-bound and
  /// never stored on the profile itself.
  IsCloudProfileProvider._({
    required IsCloudProfileFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'isCloudProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isCloudProfileHash();

  @override
  String toString() {
    return r'isCloudProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as int;
    return isCloudProfile(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsCloudProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isCloudProfileHash() => r'aa2c1a6c6616c1cfb60a7f0d2ddfd39122cabc07';

/// The synced profile is read-only in the UI; membership is account-bound and
/// never stored on the profile itself.

final class IsCloudProfileFamily extends $Family
    with $FunctionalFamilyOverride<bool, int> {
  IsCloudProfileFamily._()
    : super(
        retry: null,
        name: r'isCloudProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The synced profile is read-only in the UI; membership is account-bound and
  /// never stored on the profile itself.

  IsCloudProfileProvider call(int profileId) =>
      IsCloudProfileProvider._(argument: profileId, from: this);

  @override
  String toString() => r'isCloudProfileProvider';
}

@ProviderFor(cloudAccount)
final cloudAccountProvider = CloudAccountProvider._();

final class CloudAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudAccount?>,
          CloudAccount?,
          FutureOr<CloudAccount?>
        >
    with $FutureModifier<CloudAccount?>, $FutureProvider<CloudAccount?> {
  CloudAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudAccountHash();

  @$internal
  @override
  $FutureProviderElement<CloudAccount?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudAccount?> create(Ref ref) {
    return cloudAccount(ref);
  }
}

String _$cloudAccountHash() => r'58bde21e2abc9d9304288fc9b3f6bbb80242776c';

@ProviderFor(CloudAction)
final cloudActionProvider = CloudActionProvider._();

final class CloudActionProvider extends $NotifierProvider<CloudAction, void> {
  CloudActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudActionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudActionHash();

  @$internal
  @override
  CloudAction create() => CloudAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$cloudActionHash() => r'e1621babdd086f86b32878f5cbe9bfeabfb2ab0c';

abstract class _$CloudAction extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
