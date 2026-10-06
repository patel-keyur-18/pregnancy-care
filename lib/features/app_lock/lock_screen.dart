import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/app_lock/app_lock.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// "Navmaas is locked" (prototype "App lock screen"). Asks the phone to
/// unlock as soon as it shows, and again from Unlock.
class LockScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  var _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_unlock()));
  }

  Future<void> _unlock() async {
    if (_asking || !mounted) return;
    setState(() => _asking = true);
    await ref
        .read(appLockProvider.notifier)
        .unlock(AppLocalizations.of(context).unlockReason);
    if (mounted) setState(() => _asking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ios = theme.platform == TargetPlatform.iOS;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height * 0.6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 14,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primaryContainer,
                        ),
                        alignment: Alignment.center,
                        child: NmIcon(
                          NavmaasIcon.lock,
                          size: 36,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.lockedTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge!.copyWith(
                            fontSize: 22,
                            height: 28 / 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        ios ? l10n.lockedHowIos : l10n.lockedHowAndroid,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontSize: 15,
                          height: 22 / 15,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: FilledButton(
                onPressed: _asking ? null : _unlock,
                child: Text(l10n.unlockButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the app switcher shows while app lock is on: the sprout mark on
/// the background colour, never her data.
class PrivacyCover extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primaryContainer,
          ),
          alignment: Alignment.center,
          child: NmIcon(
            NavmaasIcon.sprout,
            size: 40,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
