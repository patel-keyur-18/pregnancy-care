import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// One chapter: its title and paragraphs (a `<br>` is a `\n` inside one).
typedef EpubChapter = ({String title, List<String> paragraphs});

/// A DRM-free EPUB as text (M9b): its own title, if any, and at least one
/// chapter in reading order.
typedef EpubBook = ({String? title, List<EpubChapter> chapters});

enum EpubProblem { unreadable, locked }

class EpubException implements Exception {
  const new(this.problem);

  final EpubProblem problem;

  @override
  String toString() => 'EpubException(${problem.name})';
}

const _unreadable = EpubException(EpubProblem.unreadable);

/// Font obfuscation (IDPF, Adobe) lives in `encryption.xml` too, but the
/// text stays readable: not DRM.
const _fontObfuscation = {
  'http://www.idpf.org/2008/embedding',
  'http://ns.adobe.com/pdf/enc#RC',
};

const _skipped = {
  'head', 'img', 'svg', 'table', 'script', 'style', 'math', 'audio', //
  'video', 'object', 'iframe',
};
const _blocks = {'p', 'li', 'blockquote', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};
const _headings = {'h1', 'h2', 'h3'};
const _html = XmlDefaultEntityMapping.html5();

/// The quick check at import: throws [EpubException] when [bytes] isn't a
/// readable EPUB or is locked; otherwise returns the book's title.
String? inspectEpub(Uint8List bytes) => _Package.open(bytes).title;

/// Reads the whole book. Top-level, for `compute()`.
EpubBook parseEpub(Uint8List bytes) {
  final pkg = _Package.open(bytes);
  final titles = pkg.tocTitles();
  final chapters = <EpubChapter>[];
  for (final path in pkg.spine) {
    final source = pkg.text(path);
    if (source == null) continue;
    final (:heading, :paragraphs) = _readXhtml(source);
    final title = titles[path] ?? heading;
    if (title == null) {
      if (chapters.isNotEmpty) {
        chapters.last.paragraphs.addAll(paragraphs);
      } else if (paragraphs.isNotEmpty) {
        chapters.add((title: pkg.title ?? '', paragraphs: paragraphs));
      }
      continue;
    }
    if (paragraphs.isNotEmpty && _same(paragraphs.first, title)) {
      paragraphs.removeAt(0);
    }
    chapters.add((title: title, paragraphs: paragraphs));
  }
  chapters.removeWhere((c) => c.paragraphs.isEmpty);
  if (chapters.isEmpty) throw _unreadable;
  return (title: pkg.title, chapters: chapters);
}

class _Package {
  // Not const: `_manifest` is a late field with an initializer.
  new _(this._archive, this.opfPath, this.opf);

  factory open(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw _unreadable;
    }
    String? read(String path) => switch (archive.findFile(path)) {
      final f? => utf8.decode(f.content, allowMalformed: true),
      null => null,
    };
    try {
      if (read('META-INF/encryption.xml') case final enc?) {
        final drm = _all(
          XmlDocument.parse(enc),
          'EncryptionMethod',
        ).any((m) => !_fontObfuscation.contains(m.getAttribute('Algorithm')));
        if (drm) throw const EpubException(EpubProblem.locked);
      }
      final container = XmlDocument.parse(read('META-INF/container.xml')!);
      final opfPath = _all(
        container,
        'rootfile',
      ).first.getAttribute('full-path')!;
      return _Package._(archive, opfPath, XmlDocument.parse(read(opfPath)!));
    } on EpubException {
      rethrow;
    } on Object {
      throw _unreadable;
    }
  }

  final Archive _archive;
  final String opfPath;
  final XmlDocument opf;

  String? text(String path) => switch (_archive.findFile(path)) {
    final f? => utf8.decode(f.content, allowMalformed: true),
    null => null,
  };

  String? get title => switch (_all(opf, 'title').firstOrNull) {
    final t? when _clean(t.innerText).isNotEmpty => _clean(t.innerText),
    _ => null,
  };

  late final Map<String, XmlElement> _manifest = {
    for (final item in _all(opf, 'item')) ?item.getAttribute('id'): item,
  };

  String? _href(XmlElement? item) => switch (item?.getAttribute('href')) {
    final h? => _resolve(opfPath, h),
    null => null,
  };

  /// The spine's documents, in reading order.
  List<String> get spine => [
    for (final ref in _all(opf, 'itemref'))
      ?_href(_manifest[ref.getAttribute('idref')]),
  ];

  /// Document path → its title in the EPUB 3 nav or the EPUB 2 ncx. Empty
  /// when there's none or it can't be read: headings name the chapters.
  Map<String, String> tocTitles() {
    final titles = <String, String>{};
    void add(String base, String? href, String title) {
      if (href != null && title.isNotEmpty) {
        titles.putIfAbsent(_resolve(base, href), () => title);
      }
    }

    try {
      final nav = _manifest.values
          .where(
            (i) =>
                (i.getAttribute('properties') ?? '').split(' ').contains('nav'),
          )
          .firstOrNull;
      if (_href(nav) case final navPath?) {
        final doc = XmlDocument.parse(text(navPath)!, entityMapping: _html);
        final navs = _all(doc, 'nav');
        final toc =
            navs
                .where(
                  (n) => n.attributes.any(
                    (a) =>
                        a.localName == 'type' &&
                        a.value.split(' ').contains('toc'),
                  ),
                )
                .firstOrNull ??
            navs.firstOrNull;
        for (final a in toc == null ? const <XmlElement>[] : _all(toc, 'a')) {
          add(navPath, a.getAttribute('href'), _clean(_text(a)));
        }
        return titles;
      }
      final ncxId = _all(opf, 'spine').firstOrNull?.getAttribute('toc');
      if (_href(_manifest[ncxId]) case final ncxPath?) {
        final doc = XmlDocument.parse(text(ncxPath)!, entityMapping: _html);
        for (final point in _all(doc, 'navPoint')) {
          add(
            ncxPath,
            _all(point, 'content').firstOrNull?.getAttribute('src'),
            _clean(_all(point, 'text').firstOrNull?.innerText ?? ''),
          );
        }
      }
    } on Object {
      // A broken TOC: headings name the chapters.
    }
    return titles;
  }
}

Iterable<XmlElement> _all(XmlNode node, String localName) =>
    node.descendantElements.where((e) => e.localName == localName);

/// [href] relative to the file at [base], without its `#fragment`.
String _resolve(String base, String href) {
  final path = href.split('#').first;
  String decoded;
  try {
    decoded = Uri.decodeComponent(path);
  } on Object {
    decoded = path; // a stray % stays as written
  }
  return p.posix.normalize(p.posix.join(p.posix.dirname(base), decoded));
}

/// Paragraphs of one spine document and its first `h1`–`h3`.
({String? heading, List<String> paragraphs}) _readXhtml(String source) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(source, entityMapping: _html);
  } on Object {
    return _stripped(source);
  }
  final body = _all(doc, 'body').firstOrNull ?? doc.rootElement;
  String? heading;
  final paragraphs = <String>[];
  void walk(XmlElement e) {
    for (final child in e.childElements) {
      final name = child.localName.toLowerCase();
      if (_skipped.contains(name)) continue;
      final leaf =
          _blocks.contains(name) &&
          !child.descendantElements.any(
            (d) => _blocks.contains(d.localName.toLowerCase()),
          );
      if (!leaf) {
        walk(child);
        continue;
      }
      final text = _clean(_text(child));
      if (text.isEmpty) continue;
      if (heading == null && _headings.contains(name)) heading = text;
      paragraphs.add(text);
    }
  }

  walk(body);
  // Text only in <div>s: keep it rather than lose the chapter.
  if (paragraphs.isEmpty) return _stripped(source);
  return (heading: heading, paragraphs: paragraphs);
}

/// [node]'s text: source whitespace is one space, `<br>` is `\n`.
String _text(XmlNode node) => switch (node) {
  XmlText(:final value) ||
  XmlCDATA(:final value) => value.replaceAll(RegExp(r'\s+'), ' '),
  XmlElement(:final localName) when localName.toLowerCase() == 'br' => '\n',
  XmlElement(:final localName)
      when _skipped.contains(localName.toLowerCase()) =>
    '',
  XmlElement() => node.children.map(_text).join(),
  _ => '',
};

/// Collapses spaces (NBSP too) and trims each line; drops empty lines.
String _clean(String s) => [
  for (final line in s.split('\n'))
    if (line.replaceAll(RegExp(r'\s+'), ' ').trim() case final l
        when l.isNotEmpty)
      l,
].join('\n');

bool _same(String a, String b) =>
    _clean(a).toLowerCase() == _clean(b).toLowerCase();

/// For a document that won't parse: its text with the tags stripped, split
/// into paragraphs at block ends.
({String? heading, List<String> paragraphs}) _stripped(String source) {
  final text = source
      .replaceAll(
        RegExp(
          r'<(head|script|style|svg|table)\b.*?</\1\s*>',
          caseSensitive: false,
          dotAll: true,
        ),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(r'</(p|li|blockquote|h[1-6]|div)\s*>', caseSensitive: false),
        '\n\n',
      )
      .replaceAll(RegExp('<[^>]*>'), '');
  return (
    heading: null,
    paragraphs: [
      for (final block in _html.decode(text).split(RegExp(r'\n\s*\n')))
        if (_clean(block) case final c when c.isNotEmpty) c,
    ],
  );
}
