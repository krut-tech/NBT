import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateOnlyFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(dynamic date) {
    if (date == null) return '-';
    if (date is String) {
      final parsed = DateTime.tryParse(date);
      if (parsed == null) return date;
      return _dateOnlyFormat.format(parsed.toLocal());
    } else if (date is DateTime) {
      return _dateOnlyFormat.format(date.toLocal());
    }
    return '-';
  }

  static String formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '-';
    if (dateTime is String) {
      final parsed = DateTime.tryParse(dateTime);
      if (parsed == null) return dateTime;
      return _dateTimeFormat.format(parsed.toLocal());
    } else if (dateTime is DateTime) {
      return _dateTimeFormat.format(dateTime.toLocal());
    }
    return '-';
  }

  static String toIsoDate(DateTime date) {
    return _isoFormat.format(date);
  }
}
