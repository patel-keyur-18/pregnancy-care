import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// The visit summary PDF (filled in by the summary task).
class VisitSummaryScreen extends ConsumerWidget {
  const new({this.visitId, super.key});

  final String? visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).summaryMake)),
  );
}
