import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/birth_prep/data/bag_repository.dart';
import 'package:navmaas/features/birth_prep/data/birth_plan_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late String pregnancyId;
  late BagRepository bag;

  const template = <BagTemplateItem>[
    (key: 'bag-me-gown', section: BagSection.forMe, label: 'Nightwear'),
    (key: 'bag-baby-cap', section: BagSection.forBaby, label: 'Soft cap'),
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
    pregnancyId = (await db.select(db.pregnancies).getSingle()).id;
    bag = BagRepository(db);
  });
  tearDown(() => db.close());

  Future<List<BagRow>> rows([
    List<BagTemplateItem> t = template,
    String? id,
  ]) async => mergeBag(t, await bag.watch(id ?? pregnancyId).first);

  test(
    'template items start unpacked; a tick persists and comes off',
    () async {
      expect((await rows()).map((r) => r.packed), [false, false]);
      await bag.setPacked(
        pregnancyId: pregnancyId,
        row: (await rows())[0],
        packed: true,
      );
      expect((await rows()).map((r) => r.packed), [true, false]);
      await bag.setPacked(
        pregnancyId: pregnancyId,
        row: (await rows())[0],
        packed: false,
      );
      expect((await rows()).map((r) => r.packed), [false, false]);
    },
  );

  test('a reworded template item keeps its tick; a removed one goes', () async {
    await bag.setPacked(
      pregnancyId: pregnancyId,
      row: (await rows())[0],
      packed: true,
    );
    const edited = <BagTemplateItem>[
      (
        key: 'bag-me-gown',
        section: BagSection.forMe,
        label: 'Two nightwear sets',
      ),
    ];
    expect((await rows(edited)).map((r) => (r.label, r.packed)), [
      ('Two nightwear sets', true),
    ]);
  });

  test('her own items: trimmed, blank refused, ticked, removed', () async {
    await bag.addOwn(
      pregnancyId: pregnancyId,
      label: '  Phone charger ',
      section: BagSection.forMe,
    );
    await bag.addOwn(
      pregnancyId: pregnancyId,
      label: '   ',
      section: BagSection.forMe,
    );
    var own = (await rows()).where((r) => r.templateKey == null).toList();
    expect(own.map((r) => (r.label, r.section, r.packed)), [
      ('Phone charger', BagSection.forMe, false),
    ]);
    await bag.setPacked(
      pregnancyId: pregnancyId,
      row: own.single,
      packed: true,
    );
    own = (await rows()).where((r) => r.templateKey == null).toList();
    expect(own.single.packed, isTrue);
    await bag.deleteOwn(own.single.id!);
    expect((await rows()).where((r) => r.templateKey == null), isEmpty);
  });

  test('a new pregnancy starts with an empty bag and birth plan', () async {
    await bag.setPacked(
      pregnancyId: pregnancyId,
      row: (await rows())[0],
      packed: true,
    );
    final plan = BirthPlanRepository(db);
    await plan.save(
      pregnancyId: pregnancyId,
      promptKey: 'plan-with-me',
      answer: 'Mum',
    );
    final pregnancies = PregnancyRepository(db);
    await pregnancies.setStatus(pregnancyId, PregnancyStatus.ended);
    await pregnancies.saveDating(method: .lmp, date: DateTime.utc(2027, 4, 2));
    final second =
        (await (db.select(db.pregnancies)
                  ..where((t) => t.status.equalsValue(PregnancyStatus.active)))
                .getSingle())
            .id;
    expect(second, isNot(pregnancyId));
    expect((await rows(template, second)).map((r) => r.packed), [false, false]);
    expect(await plan.watch(second).first, isEmpty);
  });

  test('birth plan: save, edit, clear with a blank answer', () async {
    final plan = BirthPlanRepository(db);
    await plan.save(
      pregnancyId: pregnancyId,
      promptKey: 'plan-with-me',
      answer: 'Mum',
    );
    await plan.save(
      pregnancyId: pregnancyId,
      promptKey: 'plan-with-me',
      answer: ' Mum and my sister ',
    );
    expect(await plan.watch(pregnancyId).first, {
      'plan-with-me': 'Mum and my sister',
    });
    await plan.save(
      pregnancyId: pregnancyId,
      promptKey: 'plan-with-me',
      answer: '  ',
    );
    expect(await plan.watch(pregnancyId).first, isEmpty);
  });

  test('removing her own bag item stamps when it changed', () async {
    await bag.addOwn(
      pregnancyId: pregnancyId,
      label: 'Her shawl',
      section: BagSection.forMe,
    );
    final id = (await db.select(db.bagItems).getSingle()).id;
    final later = DateTime(2026, 10, 6, 8);
    clockNow = () => later;
    addTearDown(() => clockNow = DateTime.now);
    await bag.deleteOwn(id);
    final row = await db.select(db.bagItems).getSingle();
    expect(row.deletedAt, later);
    expect(row.updatedAt, later);
  });
}
