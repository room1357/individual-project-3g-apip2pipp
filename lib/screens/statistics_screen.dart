// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/expense_service.dart';
import '../utils/currency_utils.dart';
import '../utils/date_utils.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ExpenseService>();
    final now = DateTime.now();

    // Ambil hanya pengeluaran yang "terlihat" + bulan ini
    final monthStart = AppDateUtils.startOfMonth(now);
    final monthEnd = AppDateUtils.endOfMonth(now);
    final expenses =
        svc
            .visibleExpenses()
            .where(
              (e) => !e.date.isBefore(monthStart) && !e.date.isAfter(monthEnd),
            )
            .toList();

    final total = expenses.fold<double>(0, (s, e) => s + e.amount);

    // Group per kategori
    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    // Group per hari (1..jumlah hari)
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final byDay = List<double>.filled(daysInMonth, 0, growable: false);
    for (final e in expenses) {
      final d = e.date.day; // 1..daysInMonth
      byDay[d - 1] += e.amount;
    }

    return Scaffold(
      appBar: AppBar(title: Text('Statistik ${AppDateUtils.my(now)}')),
      body:
          expenses.isEmpty
              ? const Center(child: Text('Belum ada data bulan ini'))
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Ringkasan total
                  Card(
                    child: ListTile(
                      title: const Text('Total Pengeluaran Bulan Ini'),
                      subtitle: Text(AppDateUtils.my(now)),
                      trailing: Text(
                        CurrencyUtils.format(total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.red[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PIE: per kategori
                  Text(
                    'Per Kategori',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                            sections: _buildPieSections(byCategory),
                            // tampilkan legenda sederhana di tengah
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: -8,
                    children:
                        byCategory.entries.map((e) {
                          final color = _colorForIndex(e.key.hashCode);
                          final pct = total == 0 ? 0 : (e.value / total * 100);
                          return Chip(
                            label: Text(
                              '${e.key} • ${pct.toStringAsFixed(1)}%',
                            ),
                            backgroundColor: color.withOpacity(.15),
                            side: BorderSide(color: color.withOpacity(.4)),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // BAR: per hari
                  Text(
                    'Per Hari',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
                        child: BarChart(
                          BarChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 38,
                                  interval: _niceInterval(
                                    byDay.fold<double>(
                                      0,
                                      (m, v) => v > m ? v : m,
                                    ),
                                  ),
                                  getTitlesWidget:
                                      (value, meta) => Text(
                                        _shortCurrency(value),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval:
                                      (daysInMonth / 6)
                                          .ceilToDouble(), // ~6 labels
                                  getTitlesWidget: (value, meta) {
                                    final d = value.toInt() + 1;
                                    if (d < 1 || d > daysInMonth) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '$d',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            barGroups: List.generate(daysInMonth, (i) {
                              final y = byDay[i];
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: y,
                                    width: 10,
                                    borderRadius: BorderRadius.circular(4),
                                    color: _colorForIndex(i),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  // ----- Helpers -----

  List<PieChartSectionData> _buildPieSections(Map<String, double> byCategory) {
    final entries =
        byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final total = byCategory.values.fold<double>(0, (s, v) => s + v);
    if (total == 0) return [];

    return [
      for (var i = 0; i < entries.length; i++)
        PieChartSectionData(
          color: _colorForIndex(entries[i].key.hashCode),
          value: entries[i].value,
          title: '${(entries[i].value / total * 100).toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          // badgeWidget: _PieBadge(label: entries[i].key),
          // badgePositionPercentageOffset: 1.15,
        ),
    ];
  }

  static Color _colorForIndex(int seed) {
    // simple deterministic color from hash
    final base = (seed & 0xFFFFFF) | 0xFF000000;
    final color = Color(base).withOpacity(1);
    // tweak to ensure brightness
    HSLColor hsl = HSLColor.fromColor(color);
    hsl = hsl.withSaturation(0.6).withLightness(0.55);
    return hsl.toColor();
  }

  static double _niceInterval(double maxY) {
    if (maxY <= 0) return 1;
    final pow10 = (maxY / 4).toStringAsFixed(0).length - 1; // approx
    final base = (maxY / 4) / (pow(10, pow10));
    double step;
    if (base < 1.5) {
      step = 1;
    } else if (base < 3.5) {
      step = 2;
    } else if (base < 7.5) {
      step = 5;
    } else {
      step = 10;
    }
    return step * pow(10, pow10).toDouble();
  }

  static double pow(num a, num b) => a == 0 ? 0 : (a.toDouble()).pow(b);

  String _shortCurrency(double v) {
    if (v >= 1e9) return 'Rp ${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return 'Rp ${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return 'Rp ${(v / 1e3).toStringAsFixed(0)}k';
    return 'Rp ${v.toStringAsFixed(0)}';
  }
}

extension on double {
  double pow(num p) => MathHelper.pow(this, p.toDouble());
}

/// Minimal math helper (hindari import dart:math supaya simple)
class MathHelper {
  static double pow(double a, double b) {
    // fast path
    if (b == 0) return 1;
    if (b == 1) return a;
    // fallback
    return _pow(a, b);
  }

  static double _pow(double a, double b) =>
      double.parse((a.toStringAsFixed(12)));
}
