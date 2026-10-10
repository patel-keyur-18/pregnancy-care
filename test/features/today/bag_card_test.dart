import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';

import '../../helpers.dart';

/// Week 33 on the test's today (5 Oct 2026); week 25 with [early].
Future<void> Function(AppDatabase) _seed({
  bool early = false,
  bool allPacked = false,
}) => (db) async {
  await PregnancyRepository(db).saveDating(
    method: .lmp,
    date: early ? DateTime.utc(2026, 4, 15) : DateTime.utc(2026, 2, 20),
  );
  if (!allPacked) return;
  final id = (await db.select(db.pregnancies).getSingle()).id;
  final items =
      (jsonDecode(File('assets/content/hospital_bag.json').readAsStringSync())
              as Map<String, Object?>)['items']!
          as List<Object?>;
  for (final i in items.cast<Map<String, Object?>>()) {
    await db
        .into(db.bagItems)
        .insert(
          BagItemsCompanion.insert(
            pregnancyId: id,
            templateKey: Value(i['key']! as String),
            section: BagSection.values.byName(i['section']! as String),
            packed: const Value(true),
          ),
        );
  }
};

void main() {
  testWidgets('before week 32, Today has no Hospital bag card', (tester) async {
    await pumpApp(tester, seed: _seed(early: true));
    expect(find.text('Hospital bag'), findsNothing);
  });

  testWidgets('from week 32: how much is packed, one tap to the bag', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seed());
    expect(find.text('Hospital bag'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^0 of \d+ packed$')), findsOneWidget);
    await tester.tap(find.text('Hospital bag'));
    await tester.pumpAndSettle();
    expect(find.text('For me'), findsOneWidget);
  });

  testWidgets('all packed: the card stays and says so', (tester) async {
    await pumpApp(tester, seed: _seed(allPacked: true));
    expect(find.text('Hospital bag'), findsOneWidget);
    expect(find.text('All packed'), findsOneWidget);
  });
}
