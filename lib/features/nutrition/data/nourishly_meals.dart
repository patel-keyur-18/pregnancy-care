import 'package:navmaas/core/platform/nourishly.dart';
import 'package:navmaas/features/nutrition/domain/nourishly_share.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nourishly_meals.g.dart';

Duration? _never(int retryCount, Object error) => null;

/// What Nourishly shares (M8b). Null: not shared; an error: there is a file
/// Navmaas can't read. Never stored. Re-read on resume (`app.dart`) and when
/// Nutrition opens; no automatic retry (a broken file stays broken).
@Riverpod(retry: _never)
Future<NourishlyShare?> nourishlyShare(Ref ref) async {
  final text = await ref.watch(nourishlySourceProvider).readShare();
  if (text == null) return null;
  return parseNourishlyShare(text) ??
      (throw const FormatException("Nourishly's share file"));
}
