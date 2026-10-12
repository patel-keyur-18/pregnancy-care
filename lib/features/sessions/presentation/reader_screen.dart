import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:navmaas/features/screen_rest/data/screen_use.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:navmaas/features/sessions/domain/epub.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/features/sessions/presentation/sessions_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';

/// Text progress is stored as thousandths of the way through.
const _textTotal = 1000;

/// EPUB progress is finer (M9b): a novel is hundreds of thousands of
/// pixels, and its place must land on the chapter she was in.
const _epubTotal = 100000;

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

  /// A text or EPUB as paragraphs; headings are marked.
  List<({String text, bool heading})>? _paragraphs;

  /// EPUB only: each chapter's title and its heading's paragraph index.
  List<({String title, int at})>? _chapters;
  List<GlobalKey> _chapterKeys = const [];

  /// The chapter she is in (EPUB).
  int _chapter = 0;
  bool _failed = false;
  int? _page;
  int? _pages;
  bool? _night;

  /// How far through a text, in [_total]ths, kept as she scrolls (the
  /// scroll view is gone by the time dispose() runs).
  int? _textPosition;

  /// Seconds left of an eye rest (Screen Rest → Eye-rest nudge).
  int _eyeRestLeft = 0;

  /// How finely a text's place is stored: [_epubTotal] or [_textTotal].
  int get _total => _item?.kind == LibraryKind.epub ? _epubTotal : _textTotal;

  @override
  void onSecond() {
    if (_eyeRestLeft > 0) {
      _eyeRestLeft--;
    } else if (seconds % eyeRestEvery == 0 &&
        (ref.read(eyeRestProvider).value ?? true)) {
      _eyeRestLeft = eyeRestSeconds;
    }
  }

  @override
  void initState() {
    super.initState();
    _library = ref.read(libraryRepositoryProvider);
    _sessions = ref.read(sessionRepositoryProvider);
    _pregnancyId = ref.read(activePregnancyProvider).value?.id;
    _scroll.addListener(() {
      final max = _scroll.position.maxScrollExtent;
      if (max > 0) {
        _textPosition = (_scroll.offset / max * _total).round().clamp(
          0,
          _total,
        );
      }
      _trackChapter();
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
      List<({String text, bool heading})>? paragraphs;
      List<({String title, int at})>? chapters;
      if (item.kind == LibraryKind.text) {
        paragraphs = [
          for (final p in paragraphsOf(
            utf8.decode(await file.readAsBytes(), allowMalformed: true),
          ))
            (
              text: p.replaceFirst(RegExp(r'^#+\s*'), ''),
              heading: p.startsWith('#'),
            ),
        ];
      } else if (item.kind == LibraryKind.epub) {
        // Off the UI isolate: a large book mustn't block a frame.
        final book = await compute(parseEpub, await file.readAsBytes());
        paragraphs = [];
        chapters = [];
        for (final c in book.chapters) {
          final title = c.title.isEmpty ? item.title : c.title;
          chapters.add((title: title, at: paragraphs.length));
          paragraphs
            ..add((text: title, heading: true))
            ..addAll([for (final p in c.paragraphs) (text: p, heading: false)]);
        }
      }
      if (!mounted) return;
      setState(() {
        _item = item;
        _path = file.path;
        _paragraphs = paragraphs;
        _chapters = chapters;
        _chapterKeys = [for (final _ in chapters ?? const []) GlobalKey()];
        _page = item.position + 1;
        _pages = item.total;
      });
      if (paragraphs != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          _scroll.jumpTo(
            _scroll.position.maxScrollExtent * item.position / _total,
          );
          _trackChapter(); // a jump to 0 doesn't call the listener
        });
      }
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// The scroll offset that puts chapter [i]'s heading at the top (past
  /// the end for a short last chapter). Computed from the heading's render
  /// box: the text view lays every paragraph out.
  double? _chapterOffset(int i) {
    final box = _chapterKeys[i].currentContext?.findRenderObject();
    if (box == null || !_scroll.hasClients) return null;
    return RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
  }

  /// Names the chapter she is in: the last heading at or above the top, or
  /// at the end of the book, the last heading on screen (a short last
  /// chapter never reaches the top). A reopened place is rounded to one
  /// [_total]th of the book, so it may sit up to half of that above its
  /// heading.
  void _trackChapter() {
    if (_chapterKeys.isEmpty || !_scroll.hasClients) return;
    final position = _scroll.position;
    final slack = position.maxScrollExtent / (2 * _total) + 1;
    final atEnd =
        position.pixels > slack &&
        position.pixels >= position.maxScrollExtent - slack;
    final limit = atEnd
        ? position.pixels + position.viewportDimension - 1
        : position.pixels + slack;
    var at = 0;
    for (var i = 0; i < _chapterKeys.length; i++) {
      final offset = _chapterOffset(i);
      if (offset != null && offset <= limit) at = i;
    }
    if (at != _chapter) setState(() => _chapter = at);
  }

  Future<void> _contents() async {
    final chapters = _chapters!;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => _ContentsSheet(
        bookTitle: _item!.title,
        chapters: [for (final c in chapters) c.title],
        current: _chapter,
      ),
    );
    if (picked == null || !mounted) return;
    if (_chapterOffset(picked) case final offset?) {
      _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
    }
    setState(() => _chapter = picked);
  }

  @override
  void dispose() {
    stopClock();
    final item = _item;
    if (item != null) {
      if (_textPosition case final position?) {
        unawaited(
          _library.setProgress(item.id, position: position, total: _total),
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
    ref.watch(eyeRestProvider);
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
      LibraryKind.epub when _chapters?.isNotEmpty ?? false =>
        l10n.readerChapter(_chapter + 1, _chapters![_chapter].title),
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
                        Semantics(
                          header: true,
                          child: Text(
                            item?.title ?? '',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge!.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: fg,
                            ),
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: small.copyWith(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (_chapters != null)
                    IconButton(
                      tooltip: l10n.readerContents,
                      onPressed: _contents,
                      icon: NmIcon(
                        NavmaasIcon.list,
                        size: 22,
                        strokeWidth: 1.9,
                        color: fg,
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
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _body(context, l10n, bg, fg, night)),
                  // Over the page, so the book doesn't jump.
                  if (_eyeRestLeft > 0)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _EyeRest(
                        secondsLeft: _eyeRestLeft,
                        onClose: () => setState(() => _eyeRestLeft = 0),
                      ),
                    ),
                ],
              ),
            ),
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
      final keys = {
        for (final (i, c) in (_chapters ?? const []).indexed)
          c.at: _chapterKeys[i],
      };
      // ponytail: the whole text is laid out at once (exact progress, easy
      // restore, chapter offsets); fine for books of a few hundred KB.
      return SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, p) in paragraphs.indexed)
              Padding(
                key: keys[i],
                padding: const EdgeInsets.only(bottom: 18),
                child: p.heading
                    ? Semantics(
                        header: true,
                        child: Text(
                          p.text,
                          style: AppTheme.reading.copyWith(
                            fontSize: 24,
                            height: 32 / 24,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      )
                    : Text(p.text, style: AppTheme.reading.copyWith(color: fg)),
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

/// Every 20 minutes of reading, a 20-second rest for her eyes.
const int eyeRestEvery = 20 * 60;
const eyeRestSeconds = 20;

/// "Rest your eyes: look far away for 20 seconds." with its countdown.
class _EyeRest extends StatelessWidget {
  const new({required this.secondsLeft, required this.onClose});

  final int secondsLeft;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = scheme.onTertiaryContainer;
    final style = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w700,
      color: on,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(l10n.eyeRestNow, style: style),
                ),
              ),
              ExcludeSemantics(
                child: Text(
                  l10n.eyeRestSeconds(secondsLeft),
                  style: style.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.closeButton,
                onPressed: onClose,
                icon: NmIcon(NavmaasIcon.close, size: 20, color: on),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contents (M9b): the book's chapters; tapping one returns its index.
class _ContentsSheet extends StatelessWidget {
  const new({
    required this.bookTitle,
    required this.chapters,
    required this.current,
  });

  final String bookTitle;
  final List<String> chapters;
  final int current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.readerContents,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 2, 24, 10),
              child: Text(
                '$bookTitle · ${l10n.contentsChapters(chapters.length)}',
                style: theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.outline,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                // Opens with the chapter she is in near the top.
                controller: ScrollController(
                  initialScrollOffset: current * 52.0,
                ),
                itemCount: chapters.length,
                itemBuilder: (context, i) {
                  final selected = i == current;
                  return Semantics(
                    selected: selected,
                    button: true,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, i),
                      child: Ink(
                        color: selected ? scheme.primaryContainer : null,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 52),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 6,
                            ),
                            child: Row(
                              spacing: 14,
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${i + 1}',
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.outline,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    chapters[i],
                                    style: AppTheme.reading.copyWith(
                                      fontSize: 16,
                                      height: 22 / 16,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Text(
                                    l10n.contentsReading,
                                    style: theme.textTheme.labelSmall!.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
