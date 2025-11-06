import 'dart:convert';
import '../utils/currency_utils.dart';

class Expense {
  final String id;

  /// Pemilik utama expense
  final String ownerId;
  final String title;
  final double amount;

  /// Simpan id kategori (string)
  final String category;
  final DateTime date;
  final String description;

  /// daftar userId yang ikut berbagi expense ini
  final List<String> sharedWith;

  const Expense({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    this.sharedWith = const [],
  });

  Expense copyWith({
    String? id,
    String? ownerId,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    List<String>? sharedWith,
  }) {
    return Expense(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      sharedWith: sharedWith ?? this.sharedWith,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    ownerId: (j['ownerId'] as String?) ?? '',
    title: j['title'] as String,
    amount: (j['amount'] as num).toDouble(),
    category: j['category'] as String,
    date: DateTime.parse(j['date'] as String),
    description: j['description'] as String? ?? '',
    sharedWith:
        (j['sharedWith'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'title': title,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'description': description,
    'sharedWith': sharedWith,
  };

  /// Getter sederhana: gunakan format rupiah lokal Indonesia
  String get formattedAmount => CurrencyUtils.format(amount);
  String get formattedDate => '${date.day}/${date.month}/${date.year}';

  // Helper opsional untuk simpan sebagai String
  String toJsonString() => jsonEncode(toJson());
  factory Expense.fromJsonString(String s) =>
      Expense.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
