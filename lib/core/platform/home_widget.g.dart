// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(widgetPublisher)
final widgetPublisherProvider = WidgetPublisherProvider._();

final class WidgetPublisherProvider
    extends
        $FunctionalProvider<WidgetPublisher, WidgetPublisher, WidgetPublisher>
    with $Provider<WidgetPublisher> {
  WidgetPublisherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetPublisherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetPublisherHash();

  @$internal
  @override
  $ProviderElement<WidgetPublisher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WidgetPublisher create(Ref ref) {
    return widgetPublisher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WidgetPublisher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WidgetPublisher>(value),
    );
  }
}

String _$widgetPublisherHash() => r'55bfc253596adf27f1a43e3c970ffdd178e36fa7';
