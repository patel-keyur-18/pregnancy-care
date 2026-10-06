import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/profile_repository.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/motion.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Questions shown on [visit]: the ones asked there, plus (for an upcoming
/// visit) every question still waiting.
List<VisitQuestion> questionsFor(
  Appointment visit,
  List<VisitQuestion> all, {
  required DateTime now,
}) => [
  for (final q in all)
    if (q.appointmentId == visit.id ||
        (q.appointmentId == null && q.askedAt == null && visit.at.isAfter(now)))
      q,
];

/// A doctor visit (prototype "Doctor visit").
class VisitScreen extends ConsumerStatefulWidget {
  const new({required this.visitId, super.key});

  final String visitId;

  @override
  ConsumerState<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends ConsumerState<VisitScreen> {
  final _question = TextEditingController();
  final _bring = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    _bring.dispose();
    super.dispose();
  }

  VisitRepository get _repo => ref.read(visitRepositoryProvider);

  Future<void> _addQuestion() async {
    final pregnancy = ref.read(activePregnancyProvider).value;
    if (_question.text.trim().isEmpty || pregnancy == null) return;
    await _repo.addQuestion(pregnancy.id, _question.text);
    _question.clear();
  }

  Future<void> _editNotes(Appointment visit) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => TextEntryDialog(
        title: AppLocalizations.of(context).visitNotes,
        initial: visit.notes,
      ),
    );
    if (notes != null) await _repo.setNotes(visit.id, notes);
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const NmIcon(NavmaasIcon.camera),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const NmIcon(NavmaasIcon.plus),
              title: Text(l10n.choosePhoto),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(l10n.photoPrivacy),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      imageQuality: 85,
    );
    if (file == null) return;
    final store = await ref.read(attachmentStoreProvider.future);
    await _repo.addAttachment(
      store,
      widget.visitId,
      await file.readAsBytes(),
      'image/jpeg',
    );
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeVisit),
        content: Text(l10n.removeVisitNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.backButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.removeVisit),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final store = await ref.read(attachmentStoreProvider.future);
    for (final a
        in ref.read(visitAttachmentsProvider(widget.visitId)).value ??
            const <Attachment>[]) {
      await _repo.removeAttachment(store, a);
    }
    await _repo.removeAppointment(widget.visitId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final brand = context.navmaas;
    final visit = (ref.watch(appointmentsProvider).value ?? const [])
        .where((a) => a.id == widget.visitId)
        .firstOrNull;
    if (visit == null) return const Scaffold();
    final now = clockNow();
    final questions = questionsFor(
      visit,
      ref.watch(visitQuestionsProvider).value ?? const [],
      now: now,
    );
    final profile = ref.watch(profileProvider).value;
    final photos =
        ref.watch(visitAttachmentsProvider(widget.visitId)).value ?? const [];
    final days = localDay(visit.at).difference(localDay(now)).inDays;
    final bring = visit.bringAlong
        .split('\n')
        .where((s) => s.isNotEmpty)
        .toList();

    Widget heading(String s) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Semantics(header: true, child: Text(s, style: text.titleMedium)),
    );

    Widget headerButton(
      NavmaasIcon icon,
      String label,
      VoidCallback? onPressed,
    ) => Expanded(
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
        ),
        onPressed: onPressed,
        icon: NmIcon(icon, size: 18, color: scheme.onSurface),
        label: Text(label),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.visitTitle),
        actions: [
          IconButton(
            tooltip: l10n.editVisit,
            onPressed: () => context.push('/care/visit-edit', extra: visit.id),
            icon: NmIcon(NavmaasIcon.pencil, color: scheme.onSurface),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          8,
          AppTheme.gutter,
          28,
        ),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: brand.amberSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        days < 0 ? l10n.visitPast : l10n.visitIn(days),
                        style: text.bodySmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: brand.onAmberSoft,
                        ),
                      ),
                      Text(
                        formatDateTime(visit.at),
                        style: text.headlineSmall!.copyWith(
                          fontSize: 22,
                          height: 28 / 22,
                          color: brand.onAmberSoft,
                        ),
                      ),
                      if ([visit.doctor, visit.place].nonNulls.join(' · ')
                          case final who when who.isNotEmpty)
                        Text(
                          who,
                          style: text.bodyLarge!.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: brand.onAmberSoft,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      headerButton(
                        NavmaasIcon.phone,
                        l10n.callClinic,
                        profile?.clinicPhone == null
                            ? null
                            : () => callClinic(profile!.clinicPhone!),
                      ),
                      headerButton(
                        NavmaasIcon.pin,
                        l10n.directions,
                        profile?.clinicAddress == null
                            ? null
                            : () => openDirections(
                                context,
                                profile!.clinicAddress!,
                              ),
                      ),
                    ],
                  ),
                  if (profile?.clinicPhone == null ||
                      profile?.clinicAddress == null)
                    Text(
                      profile?.clinicPhone == null
                          ? l10n.noClinicPhone
                          : l10n.noClinicAddress,
                      style: text.bodySmall!.copyWith(color: brand.onAmberSoft),
                    ),
                ],
              ),
            ),
          ),
          heading(l10n.questionsToAsk),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (questions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.noQuestions,
                      style: text.bodyMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (final (i, q) in questions.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _QuestionRow(
                    question: q,
                    onToggle: () => _repo.setAsked(
                      q.id,
                      asked: q.askedAt == null,
                      appointmentId: visit.id,
                    ),
                  ),
                ],
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _question,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(200),
                          ],
                          decoration: InputDecoration(
                            hintText: l10n.addQuestionHint,
                          ),
                          onSubmitted: (_) => _addQuestion(),
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(64, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _addQuestion,
                        child: Text(l10n.addButton),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          heading(l10n.bringAlong),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in bring)
                InputChip(
                  label: Text(item),
                  deleteIcon: const NmIcon(NavmaasIcon.close, size: 16),
                  deleteButtonTooltipMessage: l10n.removeBring(item),
                  onDeleted: () => _repo.setBringAlong(visit.id, [
                    for (final b in bring)
                      if (b != item) b,
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bring,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            decoration: InputDecoration(hintText: l10n.addBringHint),
            onSubmitted: (s) async {
              await _repo.setBringAlong(visit.id, [...bring, s]);
              _bring.clear();
            },
          ),
          heading(l10n.afterVisit),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                _AfterTile(
                  icon: NavmaasIcon.pencil,
                  label: l10n.visitNotes,
                  onTap: () => _editNotes(visit),
                ),
                _AfterTile(
                  icon: NavmaasIcon.camera,
                  label: l10n.prescription,
                  onTap: _addPhoto,
                ),
                _AfterTile(
                  icon: NavmaasIcon.calendar,
                  label: l10n.nextVisit,
                  onTap: () => context.push('/care/visit-edit'),
                ),
              ],
            ),
          ),
          if (visit.notes case final notes?) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(notes, style: text.bodyMedium),
              ),
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final a in photos) _Photo(attachment: a)],
            ),
          ],
          const SizedBox(height: 28),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error, width: 1.5),
            ),
            onPressed: _remove,
            child: Text(l10n.removeVisit),
          ),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const new({required this.question, required this.onToggle});

  final VisitQuestion question;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final asked = question.askedAt != null;
    return Semantics(
      container: true,
      checked: asked,
      child: InkWell(
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: asked ? scheme.primary : null,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: asked ? scheme.primary : scheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: asked
                      ? DrawOnIcon(
                          NavmaasIcon.check,
                          active: asked,
                          size: 14,
                          strokeWidth: 3.2,
                          color: scheme.onPrimary,
                          duration: const Duration(milliseconds: 250),
                        )
                      : null,
                ),
                Expanded(
                  child: Text(
                    question.body,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: asked ? scheme.outline : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AfterTile extends StatelessWidget {
  const new({required this.icon, required this.label, required this.onTap});

  final NavmaasIcon icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 6,
                children: [
                  NmIcon(icon, size: 22, color: theme.colorScheme.onSurface),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A decrypted thumbnail; tap to view, long-press to remove.
class _Photo extends ConsumerWidget {
  const new({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(attachmentStoreProvider).value;
    if (store == null) return const SizedBox.square(dimension: 96);
    return FutureBuilder<Uint8List>(
      future: store.read(attachment.fileName),
      builder: (context, snap) {
        final bytes = snap.data;
        return Semantics(
          button: true,
          label: l10n.prescription,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: bytes == null
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (context) => Dialog(
                      child: InteractiveViewer(child: Image.memory(bytes)),
                    ),
                  ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox.square(
                    dimension: 96,
                    child: bytes == null
                        ? const ColoredBox(color: Colors.black12)
                        : Image.memory(bytes, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    tooltip: l10n.removePhoto,
                    onPressed: () => ref
                        .read(visitRepositoryProvider)
                        .removeAttachment(store, attachment),
                    icon: const NmIcon(NavmaasIcon.close, size: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
