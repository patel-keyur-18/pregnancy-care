import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:navmaas/features/records/domain/visit_summary.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Static Nunito, made from the bundled OFL font (ADR 065).
typedef PdfFonts = ({ByteData regular, ByteData bold});

Future<PdfFonts> loadPdfFonts() async => (
  regular: await rootBundle.load('assets/fonts/pdf/Nunito-Regular.ttf'),
  bold: await rootBundle.load('assets/fonts/pdf/Nunito-Bold.ttf'),
);

// The printed page's own colours (board "Visit summary · the PDF"), not the
// app theme: the PDF is always light.
const _ink = PdfColor.fromInt(0xFF1F2622);
const _muted = PdfColor.fromInt(0xFF55605A);
const _sage = PdfColor.fromInt(0xFF3E5C4B);
const _rule = PdfColor.fromInt(0xFFCBD6CF);

/// Draws [doc] on A4 pages, values only, as written.
Future<Uint8List> renderSummaryPdf(
  SummaryDoc doc,
  PdfFonts fonts, {
  required String Function(int n, int m) pageLabel,
}) async {
  final regular = pw.Font.ttf(fonts.regular);
  final bold = pw.Font.ttf(fonts.bold);
  final base = pw.TextStyle(
    font: regular,
    fontBold: bold,
    fontSize: 10,
    color: _ink,
  );
  final strong = base.copyWith(fontWeight: pw.FontWeight.bold);
  final small = base.copyWith(fontSize: 9, color: _muted);
  final pdf =
      pw.Document(
        title: doc.title,
        creator: 'Navmaas',
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
      )..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginLeft: 44,
            marginRight: 44,
            marginTop: 40,
            marginBottom: 28,
          ),
          header: (context) => context.pageNumber > 1
              ? pw.SizedBox()
              : pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: _rule, width: 1.5),
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              doc.title,
                              style: strong.copyWith(fontSize: 20),
                            ),
                            pw.Text(
                              doc.subtitle,
                              style: small.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (doc.forLine case final f?) pw.Text(f, style: small),
                    ],
                  ),
                ),
          footer: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: _rule, width: 0.5)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Text(doc.footer, style: small)),
                pw.Text(
                  pageLabel(context.pageNumber, context.pagesCount),
                  style: small,
                ),
              ],
            ),
          ),
          build: (context) => [
            for (final b in doc.blocks) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 10, bottom: 3),
                child: pw.Text(
                  b.heading,
                  style: strong.copyWith(fontSize: 12, color: _sage),
                ),
              ),
              for (final line in b.lines)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: line.startsWith('## ')
                      ? pw.Text(line.substring(3), style: strong)
                      : pw.Text(line, style: base),
                ),
              if (b.table case final t?)
                pw.TableHelper.fromTextArray(
                  headers: t.header.isEmpty ? null : t.header,
                  headerCount: t.header.isEmpty ? 0 : 1,
                  data: t.rows,
                  border: null,
                  headerStyle: strong.copyWith(color: _muted),
                  cellStyle: base,
                  headerAlignment: pw.Alignment.centerLeft,
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.fromLTRB(0, 2, 10, 2),
                  headerPadding: const pw.EdgeInsets.fromLTRB(0, 2, 10, 2),
                ),
            ],
          ],
        ),
      );
  return await pdf.save();
}
