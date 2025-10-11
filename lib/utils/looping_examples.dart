import '../models/expense.dart';

class LoopingExamples {
  // ===== 1) TOTAL dengan berbagai cara =====
  static double calculateTotalTraditional(List<Expense> expenses) {
    double total = 0;
    for (int i = 0; i < expenses.length; i++) {
      total += expenses[i].amount;
    }
    return total;
  }

  static double calculateTotalForIn(List<Expense> expenses) {
    double total = 0;
    for (final e in expenses) {
      total += e.amount;
    }
    return total;
  }

  static double calculateTotalForEach(List<Expense> expenses) {
    double total = 0;
    for (var e in expenses) {
      total += e.amount;
    }
    return total;
  }

  static double calculateTotalFold(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  static double calculateTotalReduce(List<Expense> expenses) {
    if (expenses.isEmpty) return 0.0;
    return expenses.map((e) => e.amount).reduce((a, b) => a + b);
  }

  // ===== 2) MENCARI item dengan berbagai cara =====
  static Expense? findExpenseTraditional(List<Expense> expenses, String id) {
    for (int i = 0; i < expenses.length; i++) {
      if (expenses[i].id == id) return expenses[i];
    }
    return null;
  }

  static Expense? findExpenseWhere(List<Expense> expenses, String id) {
    try {
      return expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ===== 3) FILTER dengan berbagai cara =====
  static List<Expense> filterByCategoryManual(
    List<Expense> expenses,
    String category,
  ) {
    final result = <Expense>[];
    for (final e in expenses) {
      if (e.category.toLowerCase() == category.toLowerCase()) {
        result.add(e);
      }
    }
    return result;
  }

  static List<Expense> filterByCategoryWhere(
    List<Expense> expenses,
    String category,
  ) {
    final lc = category.toLowerCase();
    return expenses.where((e) => e.category.toLowerCase() == lc).toList();
  }
}
