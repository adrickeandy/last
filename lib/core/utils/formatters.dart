import 'package:intl/intl.dart';

class AppFormatters {
  /// Formats date to relative string like "2m", "5h", "3d", or "Oct 12"
  static String timeAgo(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 45) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else if (difference.inDays < 365) {
        return DateFormat('MMM d').format(dateTime);
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (_) {
      return '';
    }
  }

  /// Formats currency, e.g. "UGX 50,000" or "$15"
  static String formatCurrency(num amount, [String currency = 'UGX']) {
    final formatter = NumberFormat.currency(
      symbol: currency == 'USD' ? '\$' : '$currency ',
      decimalDigits: (amount % 1 == 0) ? 0 : 2,
    );
    return formatter.format(amount);
  }

  /// Formats event date, e.g. "Wed, 04:30 PM"
  static String formatEventDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('EEE, hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  /// Formats calendar month and day
  static String getMonthShort(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'TBA';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM').format(dt).toUpperCase();
    } catch (_) {
      return 'TBA';
    }
  }

  static String getDayNumber(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return dt.day.toString();
    } catch (_) {
      return '--';
    }
  }
}
