import 'package:intl/intl.dart';

/// Parses a date from the database, mirroring parseDate() in the website's
/// lib/dates.js: malformed values and years outside 2000–2099 become null
/// instead of crashing or stretching the timeline.
DateTime? parseDbDate(Object? value) {
  if (value == null) return null;
  final d = DateTime.tryParse(value.toString());
  if (d == null || d.year < 2000 || d.year > 2099) return null;
  return d;
}

/// Parses a timestamptz (created_at etc.) without the 2000–2099 guard.
DateTime? parseTimestamp(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

String fmtDate(DateTime? d, {String pattern = 'MMM d, y', String fallback = '—'}) =>
    d == null ? fallback : DateFormat(pattern).format(d);
