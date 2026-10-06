import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/bell.dart';

void main() {
  test('the committed bell and quiet clip are what tool/bell.dart makes', () {
    expect(
      File(bellWavPath).readAsBytesSync(),
      bellWav(),
      reason: 'run: dart run tool/bell.dart',
    );
    expect(File(quietWavPath).readAsBytesSync(), quietWav());
  });

  test('sizes: the bell is about 175 KB, the quiet clip 240 KB', () {
    expect(bellWav().length, 44 + 22050 * 4 * 2);
    expect(quietWav().length, 44 + 8000 * 30);
  });
}
