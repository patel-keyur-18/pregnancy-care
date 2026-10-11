import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// One record, opened in memory (filled in by the viewer task).
class RecordScreen extends ConsumerWidget {
  const new({required this.recordId, super.key});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).recordsTitle)),
  );
}
