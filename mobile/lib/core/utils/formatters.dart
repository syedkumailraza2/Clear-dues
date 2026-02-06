import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compactCurrencyFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _shortDateFormat = DateFormat('dd MMM');

  /// Format amount as Indian currency (₹1,234.56)
  static String formatCurrency(num amount) {
    return _currencyFormat.format(amount);
  }

  /// Format amount as compact currency (₹1.2K)
  static String formatCompactCurrency(num amount) {
    if (amount.abs() < 1000) {
      return _currencyFormat.format(amount);
    }
    return _compactCurrencyFormat.format(amount);
  }

  /// Format amount with sign (+₹500 or -₹500)
  static String formatCurrencyWithSign(num amount) {
    final formatted = _currencyFormat.format(amount.abs());
    if (amount > 0) {
      return '+$formatted';
    } else if (amount < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  /// Format date (25 Jan 2024)
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format time (02:30 PM)
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format date and time (25 Jan 2024, 02:30 PM)
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format relative date (Today, Yesterday, 25 Jan)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return _shortDateFormat.format(date);
    }
  }

  /// Format phone number (99999 99999)
  static String formatPhoneNumber(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phone;
  }

  /// Get initials from name (JD for John Doe)
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
