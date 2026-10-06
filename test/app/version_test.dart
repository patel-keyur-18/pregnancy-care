import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/backup/data/backup_service.dart';

void main() {
  test("the backup header's version is pubspec.yaml's", () {
    final version = RegExp(
      r'^version: (\d+\.\d+\.\d+)\+\d+$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())![1];
    expect(appVersion, version);
  });
}
