import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _bdt = NumberFormat.decimalPattern('en_US');

  /// Matches the website's `formatBDT`: ৳ prefix + thousands separators.
  static String bdt(num? amount) => '৳${_bdt.format(amount ?? 0)}';

  /// Compact formatting for large amounts (e.g. 95.81 cr)
  static String bdtCompact(num? amount) {
    if (amount == null || amount == 0) return '৳0';
    if (amount >= 10000000) {
      return '৳${(amount / 10000000).toStringAsFixed(2)} cr';
    } else if (amount >= 100000) {
      return '৳${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '৳${(amount / 1000).toStringAsFixed(1)} K';
    }
    return '৳${_bdt.format(amount)}';
  }

  static String number(num? value) => _bdt.format(value ?? 0);
}
