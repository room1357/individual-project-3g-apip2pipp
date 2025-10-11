import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/currency_utils.dart';
import '../utils/date_utils.dart';

class LoopingDemoScreen extends StatelessWidget {
  const LoopingDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ExpenseService>();
    final expenses = svc.visibleExpenses();

    // 1) for-in: kumpulkan judul
    final titles = <String>[];
    for (final e in expenses) {
      titles.add(e.title);
    }

    // 2) classic for (index): 3 item pertama
    final firstThree = <String>[];
    for (int i = 0; i < expenses.length && i < 3; i++) {
      firstThree.add(expenses[i].title);
    }

    // 3) forEach + index (asMap)
    final withIndex =
        expenses
            .asMap()
            .entries
            .map((it) => '#${it.key + 1} ${it.value.title}')
            .toList();

    // 4) map + where: ambil judul untuk kategori "Makanan"
    final makananTitles =
        expenses
            .where((e) => e.category.toLowerCase() == 'makanan')
            .map((e) => e.title)
            .toList();

    // 5) fold: total semua amount
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    // 6) reduce: cari pengeluaran terbesar
    final maxExpense =
        expenses.isEmpty
            ? null
            : expenses.reduce((a, b) => a.amount >= b.amount ? a : b);

    // 7) group by kategori (for-in + map)
    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    // 8) every / any
    final allAboveZero = expenses.every((e) => e.amount > 0);
    final anyBig = expenses.any((e) => e.amount >= 1000000);

    // 9) while: hapus dari akhir sampai total <= 1jt (contoh manipulasi)
    final mutable = List<Expense>.from(expenses);
    var tempTotal = mutable.fold<double>(0, (s, e) => s + e.amount);
    while (mutable.isNotEmpty && tempTotal > 1000000) {
      tempTotal -= mutable.removeLast().amount;
    }
    final trimmedCount = expenses.length - mutable.length;

    // 10) do-while: cari tanggal terdekat ke hari ini ke belakang yg punya transaksi
    DateTime probe = DateTime.now();
    DateTime? nearestDay;
    if (expenses.isNotEmpty) {
      do {
        final sameDay = expenses.any(
          (e) =>
              e.date.year == probe.year &&
              e.date.month == probe.month &&
              e.date.day == probe.day,
        );
        if (sameDay) {
          nearestDay = probe;
          break;
        }
        probe = probe.subtract(const Duration(days: 1));
      } while (true);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Demo Looping')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('1) for-in (judul)', titles.join(', ')),
          _tile('2) classic for (3 pertama)', firstThree.join(', ')),
          _tile('3) forEach + index', withIndex.join(' | ')),
          _tile(
            '4) where + map (Makanan)',
            makananTitles.isEmpty ? '-' : makananTitles.join(', '),
          ),
          _tile('5) fold (total)', CurrencyUtils.format(total)),
          _tile(
            '6) reduce (terbesar)',
            maxExpense == null
                ? '-'
                : '${maxExpense.title} • ${CurrencyUtils.format(maxExpense.amount)}',
          ),
          _tile(
            '7) group by kategori',
            byCategory.entries
                .map((e) => '${e.key}: ${CurrencyUtils.format(e.value)}')
                .join(' | '),
          ),
          _tile(
            '8) every/any',
            'Semua > 0? $allAboveZero • Ada ≥ 1jt? $anyBig',
          ),
          _tile('9) while (trim total ≤ 1jt)', 'Item dipangkas: $trimmedCount'),
          _tile(
            '10) do-while (hari terdekat ada transaksi)',
            nearestDay == null ? '-' : AppDateUtils.dmy(nearestDay),
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value.isEmpty ? '-' : value),
      ),
    );
  }
}
