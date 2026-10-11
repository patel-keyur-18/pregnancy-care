// The visit summary's text, read back by pdfium (only on a phone or the
// simulator): the chosen sections are in it, the others aren't.
//
// flutter test integration_test/visit_summary_test.dart -d <phone>

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:navmaas/features/records/domain/summary_pdf.dart';
import 'package:navmaas/features/records/domain/visit_summary.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the PDF holds the chosen headings and none of the others', (
    tester,
  ) async {
    await pdfrxFlutterInitialize();
    const SummaryDoc doc = (
      title: 'Visit summary',
      subtitle: 'Meera · Thu, 17 Sep – Mon, 5 Oct 2026',
      forLine: null,
      blocks: [
        (
          heading: 'Vitals',
          lines: ['Nothing logged in this range'],
          table: null,
        ),
        (
          heading: 'Questions',
          lines: ['• When is the next scan?'],
          table: null,
        ),
      ],
      footer:
          'Made with Navmaas on Mon, 5 Oct 2026 · values as she logged them',
    );
    final bytes = await renderSummaryPdf(
      doc,
      await loadPdfFonts(),
      pageLabel: (n, m) => 'Page $n of $m',
    );
    final pdf = await PdfDocument.openData(bytes);
    final text = (await pdf.pages.first.loadText())!.fullText;
    expect(text, contains('Vitals'));
    expect(text, contains('When is the next scan?'));
    expect(text, contains('Nothing logged in this range'));
    expect(text, isNot(contains('Birth plan')));
    expect(text, isNot(contains('Wellbeing')));
    await pdf.dispose();
  });
}
