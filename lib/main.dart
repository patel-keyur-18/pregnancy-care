import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/app/app.dart';
import 'package:navmaas/app/theme_mode.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  // Open the database and load the first values behind the native splash,
  // so the first frame is already the right screen in the right theme.
  await Future.wait([
    container.read(activePregnancyProvider.future),
    container.read(themeModeProvider.future),
  ]);
  runApp(
    UncontrolledProviderScope(container: container, child: const NavmaasApp()),
  );
}
