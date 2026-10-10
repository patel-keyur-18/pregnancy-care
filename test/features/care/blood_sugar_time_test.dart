import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/care/domain/blood_sugar_time.dart';

void main() {
  final now = DateTime(2026, 10, 5, 9, 30);

  test('a time earlier today, or now, is kept', () {
    expect(sugarTimeToday(now, 7, 40), DateTime(2026, 10, 5, 7, 40));
    expect(sugarTimeToday(now, 0, 0), DateTime(2026, 10, 5));
    expect(sugarTimeToday(now, 9, 30), DateTime(2026, 10, 5, 9, 30));
  });

  test('a time still to come today is refused', () {
    expect(sugarTimeToday(now, 9, 31), isNull);
    expect(sugarTimeToday(now, 22, 0), isNull);
  });
}
