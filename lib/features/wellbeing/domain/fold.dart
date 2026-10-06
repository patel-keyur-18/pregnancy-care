/// How many of [widths] (laid out in order, wrapping like `Wrap`) fit in
/// [rows] runs of [maxWidth] while leaving room for a "More" chip of
/// [moreWidth] after them. All of them, with no More chip, when they fit on
/// their own.
int chipsThatFit(
  List<double> widths, {
  required double moreWidth,
  required double maxWidth,
  double spacing = 8,
  int rows = 2,
}) {
  bool fits(Iterable<double> chips) {
    var run = 1;
    double? x;
    for (final w in chips) {
      final next = x == null ? w : x + spacing + w;
      if (next <= maxWidth) {
        x = next;
      } else {
        run++;
        x = w;
      }
    }
    return run <= rows;
  }

  if (fits(widths)) return widths.length;
  for (var n = widths.length - 1; n > 0; n--) {
    if (fits([...widths.take(n), moreWidth])) return n;
  }
  return 1;
}
