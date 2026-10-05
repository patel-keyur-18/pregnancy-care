/// Calendar-date maths. Dates are represented as UTC midnight, so day counts
/// never depend on time of day or the device's daylight-saving rules.
library;

import 'package:intl/intl.dart';

/// The calendar date of [local] (in the device's time zone) as UTC midnight.
DateTime dateOnly(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day);

DateTime addDays(DateTime date, int days) =>
    DateTime.utc(date.year, date.month, date.day + days);

/// Whole days from [from] to [to]; both must come from [dateOnly].
int daysBetween(DateTime from, DateTime to) => to.difference(from).inDays;

/// "Wed, 20 Jan 2027".
String formatDate(DateTime date) => DateFormat('EEE, d MMM yyyy').format(date);
