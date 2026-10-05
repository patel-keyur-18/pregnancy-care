import 'package:flutter/material.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

void main() => runApp(const NavmaasApp());

class NavmaasApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    onGenerateTitle: _title,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(),
  );
}

String _title(BuildContext context) => AppLocalizations.of(context).appTitle;
