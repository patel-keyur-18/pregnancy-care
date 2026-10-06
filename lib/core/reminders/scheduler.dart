import 'dart:convert';

import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

part 'scheduler.g.dart';

/// Notification action ids.
abstract final class ReminderAction {
  static const taken = 'taken';
  static const snooze = 'snooze';
}

/// What a scheduled reminder carries, so an action can act on it later.
class ReminderPayload {
  const new({
    required this.keys,
    required this.title,
    required this.body,
    this.actions = false,
    this.snoozed = false,
  });

  factory fromJson(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return ReminderPayload(
      keys: (m['keys'] as List).cast<String>(),
      title: m['title'] as String,
      body: m['body'] as String,
      actions: m['actions'] as bool? ?? false,
      snoozed: m['snoozed'] as bool? ?? false,
    );
  }

  final List<String> keys;
  final String title;
  final String body;
  final bool actions;
  final bool snoozed;

  String toJson() => jsonEncode({
    'keys': keys,
    'title': title,
    'body': body,
    'actions': actions,
    'snoozed': snoozed,
  });
}

/// Schedules reminders with the OS, so they fire on time whether or not the
/// app is open or the phone is locked (ARCHITECTURE §7). Behind an interface
/// so tests use a fake.
abstract interface class ReminderScheduler {
  /// Sets up time zone, channels and action handlers. Call once per isolate.
  Future<void> init({
    void Function(NotificationResponse)? onAction,
    void Function(NotificationResponse)? onBackgroundAction,
  });

  Future<bool> hasPermission();
  Future<bool> requestPermission();

  /// Makes the OS schedule match [planned]: cancels what is gone, schedules
  /// what is new or changed. Snoozed reminders are left alone.
  Future<void> sync(List<PlannedReminder> planned, AppLocalizations l10n);

  /// Shows [payload] again in 30 minutes.
  Future<void> snooze(ReminderPayload payload, AppLocalizations l10n);

  /// Re-reads the device time zone (it may change while travelling).
  Future<void> refreshTimeZone();
}

class LocalNotificationsScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'reminders';
  static const _doseCategory = 'dose';

  @override
  Future<void> init({
    void Function(NotificationResponse)? onAction,
    void Function(NotificationResponse)? onBackgroundAction,
  }) async {
    tzdata.initializeTimeZones();
    await refreshTimeZone();
    final l10n = lookupAppLocalizations(const Locale('en'));
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Asked during onboarding or from Me, never on launch.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              _doseCategory,
              actions: [
                DarwinNotificationAction.plain(
                  ReminderAction.taken,
                  l10n.actionTaken,
                ),
                DarwinNotificationAction.plain(
                  ReminderAction.snooze,
                  l10n.actionSnooze,
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: onAction,
      onDidReceiveBackgroundNotificationResponse: onBackgroundAction,
    );
  }

  @override
  Future<void> refreshTimeZone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object catch (e) {
      // Unknown zone name: keep the previous one (UTC at worst).
      debugPrint('Navmaas: time zone not set ($e)');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> hasPermission() async {
    if (_android case final android?) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final options = await _ios?.checkPermissions();
    return options?.isEnabled ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (_android case final android?) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> sync(
    List<PlannedReminder> planned,
    AppLocalizations l10n,
  ) async {
    final want = {for (final p in planned) p.id: (p, _payloadFor(p, l10n))};
    final pending = await _plugin.pendingNotificationRequests();
    final have = <int>{};
    for (final r in pending) {
      final payload = r.payload == null
          ? null
          : ReminderPayload.fromJson(r.payload!);
      if (payload?.snoozed ?? false) continue;
      final wanted = want[r.id];
      if (wanted == null || wanted.$2.toJson() != r.payload) {
        await _plugin.cancel(id: r.id);
      } else {
        have.add(r.id);
      }
    }
    final now = clockNow();
    for (final MapEntry(key: id, value: (p, payload)) in want.entries) {
      if (have.contains(id) || !p.at.isAfter(now)) continue;
      await _schedule(id, p.at, payload, l10n);
    }
  }

  @override
  Future<void> snooze(ReminderPayload payload, AppLocalizations l10n) {
    final at = clockNow().add(const Duration(minutes: 30));
    final snoozed = ReminderPayload(
      keys: payload.keys,
      title: payload.title,
      body: payload.body,
      actions: payload.actions,
      snoozed: true,
    );
    return _schedule(
      stableId('snooze@${at.toIso8601String()}#${payload.keys.join('|')}'),
      at,
      snoozed,
      l10n,
    );
  }

  ReminderPayload _payloadFor(PlannedReminder p, AppLocalizations l10n) {
    final items = p.items;
    final allDoses = items.every((i) => i.key.startsWith('dose:'));
    final String title;
    final String body;
    if (p.isDigest) {
      title = l10n.reminderDigest;
      body = items.map((i) => i.title).join(' · ');
    } else if (items.length == 1) {
      title = items.single.title;
      body = items.single.body;
    } else {
      title = items.every((i) => i.kind == ReminderKind.supplement)
          ? l10n.reminderSupplements
          : l10n.reminderGeneric;
      body = items.map((i) => i.title).join(' · ');
    }
    return ReminderPayload(
      keys: p.keys,
      title: title,
      body: body,
      actions: allDoses && !p.isDigest,
    );
  }

  Future<void> _schedule(
    int id,
    DateTime at,
    ReminderPayload payload,
    AppLocalizations l10n,
  ) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.reminderChannel,
        channelDescription: l10n.reminderChannelDescription,
        category: AndroidNotificationCategory.reminder,
        actions: payload.actions
            ? [
                AndroidNotificationAction(
                  ReminderAction.taken,
                  l10n.actionTaken,
                ),
                AndroidNotificationAction(
                  ReminderAction.snooze,
                  l10n.actionSnooze,
                ),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: payload.actions ? _doseCategory : null,
      ),
    );
    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: details,
      androidScheduleMode: mode,
      title: payload.title,
      body: payload.body,
      payload: payload.toJson(),
    );
    try {
      // On time even when the phone is locked or dozing.
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException {
      // Exact alarms switched off by the user (Android 12): a few minutes
      // late is better than missing.
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }
}

@Riverpod(keepAlive: true)
ReminderScheduler reminderScheduler(Ref ref) => LocalNotificationsScheduler();
