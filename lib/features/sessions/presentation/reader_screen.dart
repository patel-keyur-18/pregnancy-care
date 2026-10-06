import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/features/sessions/presentation/sessions_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';

/// Text progress is stored as thousandths of the way through.
const _textTotal = 1000;

/// Reading session (prototype "Reading session"): the book, a gentle 15-min
/// timer, paper or night colours. Leaving logs the time read (from 1 min)
/// and remembers the place.
class ReaderScreen extends ConsumerStatefulWidget {
  const new({required this.itemId, super.key});

  final String itemId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> with SessionClock {
  // Read up front: dispose() logs the session and can't use ref.
  late final LibraryRepository _library;
  late final SessionRepository _sessions;
  late final String? _pregnancyId;
  final DateTime _startedAt = clockNow();
  final _scroll = ScrollController();

  LibraryItem? _item;
  late String _path;
  List<String>? _paragraphs;
  bool _failed = false;
  int? _page;
  int? _pages;
  bool? _night;

  /// Thousandths of the way through a text, kept as she scrolls (the
  /// scroll view is gone by the time dispose() runs).
  int? _textPosition;

  @override
  void initState() {
    super.initState();
    _library = ref.read(libraryRepositoryProvider);
    _sessions = ref.read(sessionRepositoryProvider);
    _pregnancyId = ref.read(activePregnancyProvider).value?.id;
    _scroll.addListener(() {
      final max = _scroll.position.maxScrollExtent;
      if (max > 0) {
        _textPosition = (_scroll.offset / max * _textTotal).round().clamp(
          0,
          _textTotal,
        );
      }
    });
    startClock(); // only time on screen counts as reading
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final item = await _library.get(widget.itemId);
      if (item == null) throw StateError('missing');
      final file = await _library.file(item);
      await _library.markOpened(item.id);
      List<String>? paragraphs;
      if (item.kind == LibraryKind.text) {
        paragraphs = paragraphsOf(
          utf8.decode(await file.readAsBytes(), allowMalformed: true),
        );
      }
      if (!mounted) return;
      setState(() {
        _item = item;
        _path = file.path;
        _paragraphs = paragraphs;
        _page = item.position + 1;
        _pages = item.total;
      });
      if (paragraphs != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          _scroll.jumpTo(
            _scroll.position.maxScrollExtent * item.position / _textTotal,
          );
        });
      }
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    stopClock();
    final item = _item;
    if (item != null) {
      if (_textPosition case final position?) {
        unawaited(
          _library.setProgress(item.id, position: position, total: _textTotal),
        );
      } else if (item.kind == LibraryKind.pdf && _page != null) {
        unawaited(
          _library.setProgress(item.id, position: _page! - 1, total: _pages),
        );
      }
      if (seconds >= 60 && _pregnancyId != null) {
        unawaited(
          _sessions.log(
            pregnancyId: _pregnancyId,
            type: SessionType.reading,
            startedAt: _startedAt,
            durationSec: seconds,
            libraryItemId: item.id,
          ),
        );
      }
    }
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brand = context.navmaas;
    final scheme = theme.colorScheme;
    final nightSetting = ref.watch(nightReadingProvider).value;
    if (_night == null && nightSetting != null) {
      final hour = ref.read(nowProvider).hour;
      _night =
          theme.brightness == Brightness.dark ||
          (nightSetting && (hour >= 21 || hour < 5));
    }
    final night = _night ?? false;
    final bg = night ? brand.readNightBg : brand.readPaperBg;
    final fg = night ? brand.readNightText : brand.readPaperText;
    final item = _item;
    const goal = readGoalMinutes * 60;
    final left = goal - seconds;
    final minutes = seconds ~/ 60;
    final subtitle = switch (item?.kind) {
      LibraryKind.pdf when _pages != null && _page != null => l10n.readerPage(
        _page!,
        _pages!,
      ),
      _ => null,
    };
    final small = theme.textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w800,
      color: fg,
    );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.backTooltip,
                    onPressed: () => context.pop(),
                    icon: NmIcon(
                      NavmaasIcon.chevronLeft,
                      size: 22,
                      strokeWidth: 2,
                      color: fg,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          item?.title ?? '',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: fg,
                          ),
                        ),
                        if (subtitle != null)
                          Text(subtitle, style: small.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: night ? l10n.switchToPaper : l10n.switchToNight,
                    onPressed: () => setState(() => _night = !night),
                    icon: Text(
                      'Aa',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: Semantics(
                      label: l10n.sessionTime,
                      value: l10n.minutesShort(minutes),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (seconds / goal).clamp(0, 1),
                          minHeight: 4,
                          color: fg.withValues(alpha: 0.6),
                          backgroundColor: fg.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    left > 0
                        ? l10n.timeLeft(clockText(left))
                        : l10n.goalReached,
                    style: small.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context, l10n, bg, fg, night)),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: fg.withValues(alpha: 0.25)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Column(
                  spacing: 12,
                  children: [
                    Semantics(
                      label: l10n.readingColours,
                      child: Row(
                        spacing: 8,
                        children: [
                          for (final (isNight, label, mbg, mfg) in [
                            (
                              false,
                              l10n.paperMode,
                              brand.readPaperBg,
                              brand.readPaperText,
                            ),
                            (
                              true,
                              l10n.nightMode,
                              brand.readNightBg,
                              brand.readNightText,
                            ),
                          ])
                            Expanded(
                              child: Semantics(
                                inMutuallyExclusiveGroup: true,
                                checked: night == isNight,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                    backgroundColor: mbg,
                                    foregroundColor: mfg,
                                    textStyle: theme.textTheme.labelLarge,
                                    side: BorderSide(
                                      width: 2,
                                      color: night == isNight
                                          ? scheme.primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                  onPressed: () =>
                                      setState(() => _night = isNight),
                                  child: Text(label),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(
                          flex: 10,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 52),
                              foregroundColor: fg,
                              side: BorderSide(
                                width: 1.5,
                                color: fg.withValues(alpha: 0.45),
                              ),
                              textStyle: theme.textTheme.labelLarge!.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () => setState(() => paused = !paused),
                            child: Text(
                              paused ? l10n.resumeButton : l10n.pauseButton,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 14,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 52),
                              textStyle: theme.textTheme.labelLarge!.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () => context.pop(),
                            child: Text(
                              minutes > 0
                                  ? l10n.finishLog(minutes)
                                  : l10n.finishButton,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    Color bg,
    Color fg,
    bool night,
  ) {
    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.fileUnreadable, style: TextStyle(color: fg)),
        ),
      );
    }
    final item = _item;
    if (item == null) return const SizedBox.shrink();
    if (_paragraphs case final paragraphs?) {
      // ponytail: the whole text is laid out at once (exact progress, easy
      // restore); fine for books of a few hundred KB.
      return SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: p.startsWith('#')
                    ? Semantics(
                        header: true,
                        child: Text(
                          p.replaceFirst(RegExp(r'^#+\s*'), ''),
                          style: AppTheme.reading.copyWith(
                            fontSize: 24,
                            height: 32 / 24,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      )
                    : Text(p, style: AppTheme.reading.copyWith(color: fg)),
              ),
          ],
        ),
      );
    }
    final pdf = PdfViewer.file(
      _path,
      initialPageNumber: item.position + 1,
      params: PdfViewerParams(
        backgroundColor: bg,
        pageDropShadow: null,
        onViewerReady: (document, _) =>
            setState(() => _pages = document.pages.length),
        onPageChanged: (page) {
          if (page != null) setState(() => _page = page);
        },
      ),
    );
    return night
        ? ColorFiltered(colorFilter: _nightFilter(context), child: pdf)
        : pdf;
  }
}

/// Maps a PDF page's light-to-dark onto night reading's dark-to-amber, so
/// white pages turn `readNightBg` and black text turns `readNightText`.
ColorFilter _nightFilter(BuildContext context) {
  final brand = context.navmaas;
  final bg = brand.readNightBg;
  final fg = brand.readNightText;
  List<double> row(double b, double f) {
    final k = b - f; // per unit of luminance (0–1)
    return [k * 0.2126, k * 0.7152, k * 0.0722, 0, f * 255];
  }

  return ColorFilter.matrix([
    ...row(bg.r, fg.r),
    ...row(bg.g, fg.g),
    ...row(bg.b, fg.b),
    0,
    0,
    0,
    1,
    0,
  ]);
}

/// Splits plain text or Markdown into paragraphs at blank lines; single
/// line breaks inside a paragraph become spaces. Headings keep their `#`.
List<String> paragraphsOf(String text) => [
  for (final block in text.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n')))
    if (block.trim().isNotEmpty)
      block.trim().replaceAll(RegExp(r'\s*\n\s*'), ' '),
];
