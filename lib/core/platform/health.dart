import 'dart:io';

import 'package:health/health.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health.g.dart';

/// Steps from Apple Health or Health Connect, read only (ARCHITECTURE §10).
/// Faked in widget tests.
abstract interface class StepSource {
  /// Asks once for read access to steps. False when it's refused or Health
  /// Connect isn't installed.
  Future<bool> requestAccess();

  /// Steps taken in [from, to), or null when they can't be read.
  Future<int?> steps(DateTime from, DateTime to);
}

class DeviceSteps implements StepSource {
  final _health = Health();

  @override
  Future<bool> requestAccess() async {
    try {
      if (Platform.isAndroid && !await _health.isHealthConnectAvailable()) {
        return false;
      }
      return await _health.requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
    } on Object {
      return false;
    }
  }

  @override
  Future<int?> steps(DateTime from, DateTime to) async {
    try {
      return await _health.getTotalStepsInInterval(from, to);
    } on Object {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
StepSource stepSource(Ref ref) => DeviceSteps();

/// Today's steps so far, without asking for access (null until she allows
/// it on the Walk screen).
@riverpod
Future<int?> todaySteps(Ref ref) {
  final now = DateTime.now();
  return ref
      .watch(stepSourceProvider)
      .steps(DateTime(now.year, now.month, now.day), now);
}
