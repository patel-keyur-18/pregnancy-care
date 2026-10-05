import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await loadFirstValues(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const NavmaasApp()),
  );
}
