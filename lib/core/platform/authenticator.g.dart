// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authenticator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authenticator)
final authenticatorProvider = AuthenticatorProvider._();

final class AuthenticatorProvider
    extends $FunctionalProvider<Authenticator, Authenticator, Authenticator>
    with $Provider<Authenticator> {
  AuthenticatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authenticatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authenticatorHash();

  @$internal
  @override
  $ProviderElement<Authenticator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Authenticator create(Ref ref) {
    return authenticator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Authenticator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Authenticator>(value),
    );
  }
}

String _$authenticatorHash() => r'8feca685a78d3909f5c14f79bd1f80d1ab73ed00';
