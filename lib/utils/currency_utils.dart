import 'package:intl/intl.dart';

class CurrencyUtils {
  // Format: Rp 120.000 (tanpa desimal)
  static final NumberFormat _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(num value) => _fmt.format(value);

  /// Parse string "Rp 120.000" -> 120000.0
  static double parse(String input) {
    // buang karakter non-digit (kecuali koma/titik/minus), lalu normalisasi
    final cleaned = input
        .replaceAll(RegExp(r'[^0-9,.\-]'), '')
        .replaceAll('.', '') // 120.000 -> 120000
        .replaceAll(',', '.'); // 12,5 -> 12.5
    return double.tryParse(cleaned) ?? 0.0;
  }
}
