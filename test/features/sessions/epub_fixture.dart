import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

const fixtureChapters = [
  ('Morning light', '<h1>Morning light</h1><p>The sun came up.</p>'),
  ('The river path', '<h1>The river path</h1><p>Water ran by.</p>'),
  ('Home', '<h2>Home</h2><p>The lamp was lit.</p>'),
];

String xhtml(String body) =>
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<!DOCTYPE html>\n'
    '<html xmlns="http://www.w3.org/1999/xhtml" '
    'xmlns:epub="http://www.idpf.org/2007/ops">'
    '<head><title>x</title></head><body>$body</body></html>';

/// A small EPUB built in memory (M9b tests). Chapter files are
/// `OEBPS/text/ch1.xhtml`…; the manifest lists them in reverse so tests
/// see the spine order kept. [toc] false leaves the TOC out. [files] adds
/// or replaces files by path (an `encryption.xml`, a broken chapter).
Uint8List buildEpub({
  String title = 'Evening stories',
  List<(String, String)> chapters = fixtureChapters,
  bool epub3 = true,
  bool toc = true,
  Map<String, String> files = const {},
}) {
  final n = chapters.length;
  const xhtmlType = 'media-type="application/xhtml+xml"';
  const ncxType = 'media-type="application/x-dtbncx+xml"';
  final ncx = toc && !epub3;
  String item(String id, String href, [String extra = '']) =>
      '<item id="$id" href="$href" $xhtmlType$extra/> ';
  final manifest = [
    for (var i = n; i >= 1; i--) item('c$i', 'text/ch$i.xhtml'),
    if (toc && epub3) item('nav', 'nav.xhtml', ' properties="nav"'),
    if (ncx) item('ncx', 'toc.ncx').replaceFirst(xhtmlType, ncxType),
  ].join();
  final spine = [for (var i = 1; i <= n; i++) '<itemref idref="c$i"/> '].join();
  final navItems = [
    for (final (i, (t, _)) in chapters.indexed)
      if (t.isNotEmpty) '<li><a href="text/ch${i + 1}.xhtml">$t</a></li> ',
  ].join();
  String navPoint(int i, String t) =>
      '<navPoint id="p$i"><navLabel><text>$t</text></navLabel> '
      '<content src="text/ch${i + 1}.xhtml"/></navPoint> ';
  final navPoints = [
    for (final (i, (t, _)) in chapters.indexed)
      if (t.isNotEmpty) navPoint(i, t),
  ].join();
  final all = <String, String>{
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml':
        '<?xml version="1.0"?> <container version="1.0" '
        'xmlns="urn:oasis:names:tc:opendocument:xmlns:container"> '
        '<rootfiles><rootfile full-path="OEBPS/content.opf" '
        'media-type="application/oebps-package+xml"/></rootfiles> '
        '</container>',
    'OEBPS/content.opf':
        '<?xml version="1.0"?> '
        '<package xmlns="http://www.idpf.org/2007/opf" '
        'version="${epub3 ? '3.0' : '2.0'}"> '
        '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/"> '
        '<dc:title>$title</dc:title></metadata> '
        '<manifest>$manifest</manifest> '
        '<spine${ncx ? ' toc="ncx"' : ''}>$spine</spine></package>',
    for (final (i, (_, body)) in chapters.indexed)
      'OEBPS/text/ch${i + 1}.xhtml': xhtml(body),
    if (toc && epub3)
      'OEBPS/nav.xhtml': xhtml('<nav epub:type="toc"><ol>$navItems</ol></nav>'),
    if (ncx)
      'OEBPS/toc.ncx':
          '<?xml version="1.0"?> '
          '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" '
          'version="2005-1"><navMap>$navPoints</navMap></ncx>',
    ...files,
  };
  final archive = Archive();
  for (final MapEntry(key: path, value: text) in all.entries) {
    archive.addFile(ArchiveFile.bytes(path, utf8.encode(text)));
  }
  // A fixed time, so the same book is the same bytes.
  return ZipEncoder().encodeBytes(archive, modified: DateTime.utc(2026));
}
