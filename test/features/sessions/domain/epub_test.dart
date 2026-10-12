import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/sessions/domain/epub.dart';

import '../epub_fixture.dart';

String _encryption(String algorithm) =>
    '<?xml version="1.0"?> <encryption '
    'xmlns="urn:oasis:names:tc:opendocument:xmlns:container" '
    'xmlns:enc="http://www.w3.org/2001/04/xmlenc#"> '
    '<enc:EncryptedData><enc:EncryptionMethod Algorithm="$algorithm"/> '
    '<enc:CipherData><enc:CipherReference URI="OEBPS/text/ch1.xhtml"/> '
    '</enc:CipherData></enc:EncryptedData></encryption>';

Matcher _problem(EpubProblem p) =>
    throwsA(isA<EpubException>().having((e) => e.problem, 'problem', p));

void main() {
  test('EPUB 3: title, nav titles, spine order, heading not repeated', () {
    final book = parseEpub(buildEpub());
    expect(book.title, 'Evening stories');
    expect(
      [for (final c in book.chapters) c.title],
      ['Morning light', 'The river path', 'Home'],
    );
    expect(book.chapters.first.paragraphs, ['The sun came up.']);
  });

  test('EPUB 2: titles come from toc.ncx', () {
    final book = parseEpub(buildEpub(epub3: false));
    expect(
      [for (final c in book.chapters) c.title],
      ['Morning light', 'The river path', 'Home'],
    );
  });

  test('without a TOC the first h1–h3 names the chapter', () {
    final book = parseEpub(buildEpub(toc: false));
    expect(
      [for (final c in book.chapters) c.title],
      ['Morning light', 'The river path', 'Home'],
    );
  });

  test('images, tables, scripts and styles are skipped; br breaks a line', () {
    final book = parseEpub(
      buildEpub(
        chapters: [
          (
            'One',
            '<style>p{}</style><p>Before</p><img src="a.png"/> '
                '<svg><text>vector</text></svg> '
                '<table><tr><td>cell</td></tr></table> '
                '<script>x()</script><p>Line one<br/>line two</p> '
                '<blockquote><p>Quoted</p></blockquote><ul><li>Item</li></ul>',
          ),
        ],
      ),
    );
    expect(book.chapters.single.paragraphs, [
      'Before',
      'Line one\nline two',
      'Quoted',
      'Item',
    ]);
  });

  test('entities and Hindi text are decoded', () {
    final book = parseEpub(
      buildEpub(
        chapters: [
          (
            'One',
            '<p>A&nbsp;quiet&mdash;village&rsquo;s lamp &#8230; &amp; '
                '&#x2014;</p><p>नमस्ते, छोटे से</p>',
          ),
        ],
      ),
    );
    expect(book.chapters.single.paragraphs, [
      'A quiet—village’s lamp … & —',
      'नमस्ते, छोटे से',
    ]);
  });

  test('malformed XHTML falls back to its text', () {
    final book = parseEpub(
      buildEpub(
        files: {
          'OEBPS/text/ch2.xhtml':
              '<html><body><p>Broken <b>bold</p><p>Still&nbsp;here</p>',
        },
      ),
    );
    expect(book.chapters[1].title, 'The river path');
    expect(book.chapters[1].paragraphs, ['Broken bold', 'Still here']);
  });

  test('an untitled document joins the chapter before it', () {
    final book = parseEpub(
      buildEpub(
        chapters: [
          ('', '<p>Cover words</p>'),
          ('Morning light', '<p>The sun came up.</p>'),
          ('', '<p>More of the morning.</p>'),
          ('Home', '<p>The lamp was lit.</p>'),
        ],
      ),
    );
    expect(
      [for (final c in book.chapters) (c.title, c.paragraphs.join(' | '))],
      [
        ('Evening stories', 'Cover words'),
        ('Morning light', 'The sun came up. | More of the morning.'),
        ('Home', 'The lamp was lit.'),
      ],
    );
  });

  test('empty chapters are dropped', () {
    final book = parseEpub(
      buildEpub(
        chapters: [
          ('Part one', '<h1>Part one</h1>'),
          ('Morning light', '<p>The sun came up.</p>'),
        ],
      ),
    );
    expect([for (final c in book.chapters) c.title], ['Morning light']);
  });

  test('ncx src with a fragment and %20 still names its chapter', () {
    final book = parseEpub(
      buildEpub(
        epub3: false,
        files: {
          'OEBPS/toc.ncx':
              '<?xml version="1.0"?> '
              '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/"> '
              '<navMap><navPoint id="a"><navLabel><text>First light</text> '
              '</navLabel><content src="text/ch%31.xhtml#start"/></navPoint> '
              '</navMap></ncx>',
        },
      ),
    );
    expect(book.chapters.first.title, 'First light');
  });

  test('DRM is detected', () {
    final bytes = buildEpub(
      files: {
        'META-INF/encryption.xml': _encryption(
          'http://www.w3.org/2001/04/xmlenc#aes128-cbc',
        ),
      },
    );
    expect(() => inspectEpub(bytes), _problem(EpubProblem.locked));
    expect(() => parseEpub(bytes), _problem(EpubProblem.locked));
  });

  test('font obfuscation alone is not DRM', () {
    final bytes = buildEpub(
      files: {
        'META-INF/encryption.xml': _encryption(
          'http://www.idpf.org/2008/embedding',
        ),
      },
    );
    expect(inspectEpub(bytes), 'Evening stories');
  });

  test('not a zip, or a zip without an EPUB inside, is unreadable', () {
    expect(
      () => inspectEpub(Uint8List.fromList(utf8.encode('not a book'))),
      _problem(EpubProblem.unreadable),
    );
    expect(
      () => inspectEpub(
        buildEpub(files: {'META-INF/container.xml': '<container/>'}),
      ),
      _problem(EpubProblem.unreadable),
    );
  });

  test('a book with no text at all is unreadable', () {
    expect(
      () => parseEpub(buildEpub(chapters: [('Cover', '<img src="c.png"/>')])),
      _problem(EpubProblem.unreadable),
    );
  });

  test('text in divs, pre and lists of terms is kept', () {
    final book = parseEpub(
      buildEpub(
        chapters: [
          (
            'One',
            '<p>Prose.</p><div class="stanza">Line one<br/>line two</div>',
          ),
          ('Two', '<h2>Two</h2><div>Long text.</div><div>More.</div>'),
          (
            'Three',
            '<pre>Kept as is</pre><dl><dt>Term</dt><dd>Means</dd></dl>',
          ),
        ],
      ),
    );
    expect(
      [for (final c in book.chapters) (c.title, c.paragraphs.join(' | '))],
      [
        ('One', 'Prose. | Line one\nline two'),
        ('Two', 'Long text. | More.'),
        ('Three', 'Kept as is | Term | Means'),
      ],
    );
  });
}
