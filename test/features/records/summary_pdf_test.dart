import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/records/domain/summary_pdf.dart';
import 'package:navmaas/features/records/domain/visit_summary.dart';

PdfFonts _fonts() => (
  regular: ByteData.sublistView(
    File('assets/fonts/pdf/Nunito-Regular.ttf').readAsBytesSync(),
  ),
  bold: ByteData.sublistView(
    File('assets/fonts/pdf/Nunito-Bold.ttf').readAsBytesSync(),
  ),
);

SummaryDoc _doc({int questions = 3, String name = 'Meera'}) => (
  title: 'Visit summary',
  subtitle: '$name · Thu, 17 Sep – Mon, 5 Oct 2026',
  forLine: 'For Dr. Mehta',
  blocks: [
    (
      heading: 'Vitals',
      lines: const [],
      table: (
        header: const ['Date', 'Weight', 'Blood pressure', 'Blood sugar'],
        rows: const [
          ['Fri, 2 Oct', '61.2 kg', '112/72 mmHg', '—'],
        ],
      ),
    ),
    (
      heading: 'Questions',
      lines: [for (var i = 0; i < questions; i++) '• Question $i'],
      table: null,
    ),
    (
      heading: 'Birth plan',
      lines: const ['## Who will be with you', 'My mother'],
      table: null,
    ),
  ],
  footer: 'Made with Navmaas on Mon, 5 Oct 2026 · values as she logged them',
);

String _label(int n, int m) => 'Page $n of $m';

int _pages(Uint8List pdf) => RegExp(
  r'/Type\s*/Page\b',
).allMatches(String.fromCharCodes(pdf)).length;

void main() {
  test('a valid one-page PDF', () async {
    final bytes = await renderSummaryPdf(_doc(), _fonts(), pageLabel: _label);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(
      String.fromCharCodes(bytes.skip(bytes.length - 8)),
      contains('%%EOF'),
    );
    expect(_pages(bytes), 1);
    // Headings use the bold face, so both fonts are embedded.
    final text = String.fromCharCodes(bytes);
    expect(text, contains('/BaseFont/Nunito-Regular'));
    expect(text, contains('/BaseFont/Nunito-ExtraBold'));
  });

  test('long content runs onto more pages', () async {
    final bytes = await renderSummaryPdf(
      _doc(questions: 200),
      _fonts(),
      pageLabel: _label,
    );
    expect(_pages(bytes), greaterThan(1));
  });

  test('text the font has no glyphs for does not throw', () async {
    final bytes = await renderSummaryPdf(
      _doc(name: 'मीरा 🌙'),
      _fonts(),
      pageLabel: _label,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
