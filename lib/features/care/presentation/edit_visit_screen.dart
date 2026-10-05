import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/profile_repository.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Adds or edits a visit; doctor and clinic default to Me → Your doctor.
class EditVisitScreen extends ConsumerStatefulWidget {
  const new({this.visitId, super.key});

  final String? visitId;

  @override
  ConsumerState<EditVisitScreen> createState() => _EditVisitScreenState();
}

class _EditVisitScreenState extends ConsumerState<EditVisitScreen> {
  final _doctor = TextEditingController();
  final _place = TextEditingController();
  var _at = DateTime.now();
  var _loaded = false;
  var _saving = false;

  @override
  void dispose() {
    _doctor.dispose();
    _place.dispose();
    super.dispose();
  }

  /// Fills the form once the visit (when editing) and the doctor details
  /// have loaded.
  void _load() {
    if (_loaded) return;
    final profile = ref.watch(profileProvider);
    final visits = ref.watch(appointmentsProvider);
    if (!profile.hasValue || !visits.hasValue) return;
    _loaded = true;
    final existing = visits.value!
        .where((a) => a.id == widget.visitId)
        .firstOrNull;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _at =
        existing?.at ??
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 11);
    _doctor.text = existing?.doctor ?? profile.value?.doctorName ?? '';
    _place.text = existing?.place ?? profile.value?.clinicName ?? '';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (d != null) {
      setState(
        () => _at = DateTime(d.year, d.month, d.day, _at.hour, _at.minute),
      );
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (t != null) {
      setState(
        () => _at = DateTime(_at.year, _at.month, _at.day, t.hour, t.minute),
      );
    }
  }

  Future<void> _save(String pregnancyId) async {
    setState(() => _saving = true);
    final id = await ref
        .read(visitRepositoryProvider)
        .saveAppointment(
          id: widget.visitId,
          pregnancyId: pregnancyId,
          at: _at,
          doctor: _doctor.text,
          place: _place.text,
        );
    if (!mounted) return;
    if (widget.visitId == null) {
      context.pushReplacement('/care/visit', extra: id);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    _load();
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final pregnancy = ref.watch(activePregnancyProvider).value;
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        s,
        style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.visitId == null ? l10n.addVisit : l10n.editVisit),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.gutter,
                  0,
                  AppTheme.gutter,
                  20,
                ),
                children: [
                  label(l10n.visitDate),
                  OutlinedButton(
                    onPressed: _pickDate,
                    child: Text(formatDate(_at)),
                  ),
                  label(l10n.visitTime),
                  OutlinedButton(
                    onPressed: _pickTime,
                    child: Text(formatMinuteOfDay(_at.hour * 60 + _at.minute)),
                  ),
                  label(l10n.visitDoctor),
                  TextField(
                    controller: _doctor,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [LengthLimitingTextInputFormatter(80)],
                  ),
                  label(l10n.visitPlace),
                  TextField(
                    controller: _place,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [LengthLimitingTextInputFormatter(120)],
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
                onPressed: !_saving && pregnancy != null
                    ? () => _save(pregnancy.id)
                    : null,
                child: Text(l10n.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
