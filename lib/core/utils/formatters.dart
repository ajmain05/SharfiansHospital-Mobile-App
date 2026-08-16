import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _bdt = NumberFormat.decimalPattern('en_US');

  /// Matches the website's `formatBDT`: ৳ prefix + thousands separators.
  static String bdt(num? amount) => '৳${_bdt.format(amount ?? 0)}';

  static String number(num? value) => _bdt.format(value ?? 0);
}
