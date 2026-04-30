import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      final value = amount / 1000000000;
      return 'Rp ${value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      final value = amount / 1000000;
      return 'Rp ${value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      final value = amount / 1000;
      return 'Rp ${value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1)}K';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
}

class DateHelper {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Today';
    if (dateDay == yesterday) return 'Yesterday';
    return formatDate(date);
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
