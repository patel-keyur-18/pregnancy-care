import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/theme/brand_mark.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/onboarding/dating_form.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Welcome + optional name → dating → confirm. "Continue" on the last step
/// saves the pregnancy; the router then moves on to Today.
class OnboardingScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 3;
  final _name = TextEditingController();
  var _step = 0;
  var _dating = const DatingInput();
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_step < _steps - 1) {
      FocusScope.of(context).unfocus();
      setState(() => _step++);
      return;
    }
    setState(() => _saving = true);
    final name = _name.text.trim();
    if (name.isNotEmpty) {
      await ref
          .read(settingsRepositoryProvider)
          .put(SettingKeys.firstName, name);
    }
    await ref
        .read(pregnancyRepositoryProvider)
        .saveDating(
          method: _dating.method,
          date: _dating.date!,
          cycleLength: _dating.cycleLength,
          embryoDay: _dating.embryoDay,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final today = ref.watch(todayProvider);
    final canContinue = !_saving && (_step == 0 || _dating.isValidOn(today));

    Widget heading(String title, String body) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Semantics(header: true, child: Text(title, style: text.headlineSmall)),
        Text(
          body,
          style: text.bodyLarge!.copyWith(
            fontSize: 15,
            height: 22 / 15,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final start = _dating.start;
    final step = switch (_step) {
      0 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          heading(l10n.welcomeTitle, l10n.welcomeBody),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                l10n.firstNameLabel,
                style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700),
              ),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.givenName],
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
                decoration: InputDecoration(hintText: l10n.firstNameHint),
                onSubmitted: (_) => _continue(),
              ),
            ],
          ),
        ],
      ),
      1 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          heading(l10n.datingTitle, l10n.datingBody),
          DatingForm(
            value: _dating,
            today: today,
            onChanged: (v) => setState(() => _dating = v),
          ),
          if (start != null) DatingResultCard(start: start, today: today),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          heading(l10n.confirmTitle, l10n.confirmBody),
          DatingResultCard(start: start!, today: today),
          Text(
            l10n.datedBy(_dating.method.name),
            style: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    };

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 28,
                    children: [
                      _Header(step: _step + 1, total: _steps),
                      AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOut,
                        child: KeyedSubtree(key: ValueKey(_step), child: step),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: canContinue ? _continue : null,
                      child: Text(l10n.continueButton),
                    ),
                    if (_step > 0)
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _step--),
                        child: Text(l10n.backButton),
                      ),
                    const _PrivacyLine(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final caption = theme.textTheme.bodySmall!.copyWith(color: scheme.outline);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            const BrandMark(),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appTitle,
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontSize: 22,
                      height: 26 / 22,
                    ),
                  ),
                  Text(l10n.tagline, style: caption),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 6,
          children: [
            Text(
              l10n.stepOf(step, total),
              style: caption.copyWith(fontWeight: FontWeight.w700),
            ),
            ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  for (var i = 1; i <= total; i++)
                    Container(
                      width: 18,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= step
                            ? scheme.primary
                            : Theme.of(context)
                                  .progressIndicatorTheme
                                  .linearTrackColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrivacyLine extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: NmIcon(
            NavmaasIcon.lock,
            size: 16,
            strokeWidth: 2,
            color: color,
          ),
        ),
        Flexible(
          child: Text(
            AppLocalizations.of(context).privacyLine,
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
