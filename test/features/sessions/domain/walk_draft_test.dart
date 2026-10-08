import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/sessions/domain/walk_draft.dart';

void main() {
  final t0 = DateTime(2026, 10, 5, 9);
  DateTime at(int minutes) => t0.add(Duration(minutes: minutes));

  test('counts only the stretches she walked', () {
    var walk = WalkDraft.start(t0);
    expect(walk.running, isTrue);
    expect(walk.seconds(at(5)), 300);
    walk = walk.pause(at(5));
    expect((walk.running, walk.seconds(at(60))), (false, 300));
    expect(walk.pause(at(9)).seconds(at(60)), 300, reason: 'already paused');
    walk = walk.resume(at(30));
    expect(walk.resume(at(31)).stretches, hasLength(2));
    expect(walk.seconds(at(40)), 900);
    expect(walk.startedAt, t0);
  });

  test('survives being saved and read back', () {
    final walk = WalkDraft.start(t0).pause(at(5)).resume(at(7));
    final back = WalkDraft.decode(walk.encode())!;
    expect(back.stretches, walk.stretches);
    expect(WalkDraft.decode(null), isNull);
    expect(WalkDraft.decode('not json'), isNull);
    expect(WalkDraft.decode('[]'), isNull);
  });

  test('a walk from an earlier day ends at its midnight', () {
    final late = DateTime(2026, 10, 4, 23, 50);
    final walk = WalkDraft.start(late);
    expect(walk.startedBefore(DateTime(2026, 10, 5)), isTrue);
    expect(walk.startedBefore(DateTime(2026, 10, 4)), isFalse);
    final ended = walk.endOfItsDay();
    expect((ended.running, ended.seconds(at(600))), (false, 600));
  });
}
