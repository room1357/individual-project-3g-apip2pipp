import 'package:intl/intl.dart';

class AppDateUtils {
  /// 15 Sep 2024
  static String dmy(DateTime d) => DateFormat('dd MMM yyyy', 'id_ID').format(d);

  /// Sep 2024
  static String my(DateTime d) => DateFormat('MMM yyyy', 'id_ID').format(d);

  /// 15/09/2024 (gaya angka)
  static String slashed(DateTime d) =>
      DateFormat('dd/MM/yyyy', 'id_ID').format(d);

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime endOfMonth(DateTime d) =>
      DateTime(d.year, d.month + 1, 1).subtract(const Duration(seconds: 1));
}
