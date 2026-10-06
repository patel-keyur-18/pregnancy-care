import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget.g.dart';

/// Hands the widget snapshot to the home-screen widgets (ARCHITECTURE §10).
/// Behind an interface so tests use a fake.
abstract interface class WidgetPublisher {
  /// Saves [snapshot] where the widgets read it and redraws them. Android
  /// widgets also redraw at [updateTimes]; iOS builds its own timeline.
  Future<void> publish(String snapshot, List<DateTime> updateTimes);
}

class HomeWidgetPublisher implements WidgetPublisher {
  /// Shared with the WidgetKit extension (ARCHITECTURE §12).
  static const appGroup = 'group.com.patelkeyur.navmaas';

  /// The key the native widgets read.
  static const key = 'snapshot';

  /// The WidgetKit `kind`.
  static const iOSName = 'NavmaasWidget';
  static const androidProvider = 'com.patelkeyur.navmaas.NavmaasWidget';

  @override
  Future<void> publish(String snapshot, List<DateTime> updateTimes) async {
    try {
      if (Platform.isIOS) await HomeWidget.setAppGroupId(appGroup);
      await HomeWidget.saveWidgetData(key, snapshot);
      await HomeWidget.updateWidget(
        iOSName: iOSName,
        qualifiedAndroidName: androidProvider,
      );
      if (Platform.isAndroid) {
        await HomeWidget.scheduleWidgetUpdates(
          updateTimes,
          qualifiedAndroidName: androidProvider,
        );
      }
    } on Object catch (e) {
      debugPrint('Navmaas: widget not updated ($e)');
    }
  }
}

@Riverpod(keepAlive: true)
WidgetPublisher widgetPublisher(Ref ref) => HomeWidgetPublisher();
