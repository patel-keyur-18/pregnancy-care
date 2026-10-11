import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/app/app.dart';
import 'package:navmaas/app/reminders.dart';
import 'package:navmaas/core/platform/voice.dart';
import 'package:navmaas/features/records/data/records_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await loadFirstValues(container);
  await initReminders(container);
  // A plain voice copy left by a crash goes now (E3).
  unawaited(container.read(voiceTempDirProvider.future).then(clearVoiceTemp));
  // … and plain record copies left mid-share or mid-pick (M9a).
  unawaited(
    container
        .read(recordsTempDirProvider.future)
        .then((d) => sweepPlainCopies(d.parent)),
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const NavmaasApp()),
  );
}
