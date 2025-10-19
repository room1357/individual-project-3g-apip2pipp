import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';

class SharedExpenseService extends ChangeNotifier {
  SharedExpenseService(this._authService, this._expenseService);

  final AuthService _authService;
  final ExpenseService _expenseService;

  // === Getters ===
  List<Expense> get sharedExpenses {
    final currentUser = _authService.currentUserEmail;
    if (currentUser == null) return [];
    
    return _expenseService.expenses
        .where((expense) => 
            expense.sharedWith.isNotEmpty && 
            (expense.ownerId == currentUser || expense.sharedWith.contains(currentUser)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> get mySharedExpenses {
    final currentUser = _authService.currentUserEmail;
    if (currentUser == null) return [];
    
    return _expenseService.expenses
        .where((expense) => 
            expense.ownerId == currentUser && expense.sharedWith.isNotEmpty)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> get sharedWithMe {
    final currentUser = _authService.currentUserEmail;
    if (currentUser == null) return [];
    
    return _expenseService.expenses
        .where((expense) => 
            expense.ownerId != currentUser && expense.sharedWith.contains(currentUser))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // === Shared Expense Management ===
  Future<void> createSharedExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required String description,
    required List<String> sharedWithUserIds,
  }) async {
    final currentUser = _authService.currentUserEmail;
    if (currentUser == null) {
      throw Exception('User tidak login');
    }

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ownerId: currentUser,
      title: title,
      amount: amount,
      category: category,
      date: date,
      description: description,
      sharedWith: sharedWithUserIds,
    );

    await _expenseService.addExpense(expense);
    notifyListeners();
  }

  Future<void> updateSharedExpense({
    required String expenseId,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    List<String>? sharedWithUserIds,
  }) async {
    final currentUser = _authService.currentUserEmail;
    if (currentUser == null) {
      throw Exception('User tidak login');
    }

    final existingExpense = _expenseService.expenses
        .where((e) => e.id == expenseId)
        .firstOrNull;

    if (existingExpense == null) {
      throw Exception('Expense tidak ditemukan');
    }

    if (existingExpense.ownerId != currentUser) {
      throw Exception('Anda tidak memiliki izin untuk mengedit expense ini');
    }

    final updatedExpense = existingExpense.copyWith(
      title: title,
      amount: amount,
      category: category,
      date: date,
      description: description,
      sharedWith: sharedWithUserIds,
    );

    await _expenseService.updateExpense(updatedExpense);
    notifyListeners();
  }

  Future<void> removeFromSharedExpense(String expenseId) async {
    final currentUser = _authService.currentUserEmail;
    if (currentUser == null) {
      throw Exception('User tidak login');
    }

    final existingExpense = _expenseService.expenses
        .where((e) => e.id == expenseId)
        .firstOrNull;

    if (existingExpense == null) {
      throw Exception('Expense tidak ditemukan');
    }

    if (existingExpense.ownerId == currentUser) {
      // Owner menghapus shared expense sepenuhnya
      await _expenseService.deleteExpense(expenseId);
    } else {
      // User lain menghapus diri dari shared expense
      final updatedSharedWith = List<String>.from(existingExpense.sharedWith)
        ..remove(currentUser);
      
      final updatedExpense = existingExpense.copyWith(
        sharedWith: updatedSharedWith,
      );
      
      await _expenseService.updateExpense(updatedExpense);
    }
    
    notifyListeners();
  }

  // === Helper Methods ===
  List<String> getAvailableUsers() {
    final currentUser = _authService.currentUserEmail;
    if (currentUser == null) return [];
    
    // Untuk demo, kita akan return list user yang tersedia
    // Dalam implementasi nyata, ini akan mengambil dari database user
    return _authService.allUsers
        .where((user) => user.email != currentUser)
        .map((user) => user.email)
        .toList();
  }

  String getUserDisplayName(String email) {
    final user = _authService.allUsers
        .where((u) => u.email == email)
        .firstOrNull;
    return user?.displayName ?? email;
  }

  double calculateSharedAmount(Expense expense) {
    final totalPeople = expense.sharedWith.length + 1; // +1 untuk owner
    return expense.amount / totalPeople;
  }

  Map<String, double> calculateSplitAmounts(Expense expense) {
    final totalPeople = expense.sharedWith.length + 1;
    final amountPerPerson = expense.amount / totalPeople;
    
    final Map<String, double> splitAmounts = {};
    
    // Owner
    splitAmounts[expense.ownerId] = amountPerPerson;
    
    // Shared users
    for (final userId in expense.sharedWith) {
      splitAmounts[userId] = amountPerPerson;
    }
    
    return splitAmounts;
  }

  // === Statistics ===
  double getTotalSharedExpenses() {
    return sharedExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getMySharedExpenses() {
    return mySharedExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getSharedWithMeExpenses() {
    return sharedWithMe.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getMyShareOfExpenses() {
    return sharedExpenses.fold(0.0, (sum, expense) {
      return sum + calculateSharedAmount(expense);
    });
  }
}
