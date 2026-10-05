import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/profile_repository.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/features/onboarding/onboarding_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Me → Your doctor: name, clinic, phone and address, all optional.
class DoctorScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends ConsumerState<DoctorScreen> {
  late final Profile? _p = ref.read(profileProvider).value;
  late final _doctor = TextEditingController(text: _p?.doctorName);
  late final _clinic = TextEditingController(text: _p?.clinicName);
  late final _phone = TextEditingController(text: _p?.clinicPhone);
  late final _address = TextEditingController(text: _p?.clinicAddress);

  @override
  void dispose() {
    for (final c in [_doctor, _clinic, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(profileRepositoryProvider)
        .save(
          doctorName: _doctor.text,
          clinicName: _clinic.text,
          clinicPhone: _phone.text,
          clinicAddress: _address.text,
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.yourDoctor)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.gutter,
                  8,
                  AppTheme.gutter,
                  20,
                ),
                children: [
                  DoctorFields(
                    doctor: _doctor,
                    clinic: _clinic,
                    phone: _phone,
                    address: _address,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                8,
                AppTheme.gutter,
                16,
              ),
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
