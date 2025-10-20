import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../models/category.dart';
import 'storage_service.dart';

class ExpenseService extends ChangeNotifier {
  ExpenseService(this._storage);

  final StorageService _storage;

  final List<Expense> _expenses = [];
  final List<CategoryModel> _categories = [];
  String? _currentUser;

  String? get currentUser => _currentUser;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<CategoryModel> get categories => List.unmodifiable(_categories);

  // ---------- init ----------
  Future<void> init({required String fallbackUser}) async {
    _currentUser = await _storage.getCurrentUser() ?? fallbackUser;
    await _storage.setCurrentUser(_currentUser!);

    // Load data per user
    final eMaps = await _storage.readExpenses(_currentUser);
    final cMaps = await _storage.readCategories(_currentUser);

    _expenses
      ..clear()
      ..addAll(eMaps.map(Expense.fromJson));
    _categories
      ..clear()
      ..addAll(cMaps.map(CategoryModel.fromJson));

    // seed kategori global untuk user ini
    if (_categories.isEmpty) {
      _categories.addAll([
        CategoryModel(id: 'c-food', name: 'Makanan', ownerId: _currentUser!),
        CategoryModel(
          id: 'c-transport',
          name: 'Transportasi',
          ownerId: _currentUser!,
        ),
        CategoryModel(id: 'c-others', name: 'Lainnya', ownerId: _currentUser!),
      ]);
      await _persistCategories();
    }

    notifyListeners();
  }

  // ---------- persist helpers ----------
  Future<void> _persistExpenses() async =>
      _storage.writeExpenses(_expenses.map((e) => e.toJson()).toList(), _currentUser);
  Future<void> _persistCategories() async =>
      _storage.writeCategories(_categories.map((c) => c.toJson()).toList(), _currentUser);

  // ---------- switch user ----------
  Future<void> switchUser(String newUserId) async {
    // Simpan data user saat ini
    await _persistExpenses();
    await _persistCategories();
    
    // Switch ke user baru
    _currentUser = newUserId;
    await _storage.setCurrentUser(newUserId);
    
    // Load data user baru
    final eMaps = await _storage.readExpenses(_currentUser);
    final cMaps = await _storage.readCategories(_currentUser);

    _expenses
      ..clear()
      ..addAll(eMaps.map(Expense.fromJson));
    _categories
      ..clear()
      ..addAll(cMaps.map(CategoryModel.fromJson));

    // Seed kategori jika kosong
    if (_categories.isEmpty) {
      _categories.addAll([
        CategoryModel(id: 'c-food', name: 'Makanan', ownerId: _currentUser!),
        CategoryModel(
          id: 'c-transport',
          name: 'Transportasi',
          ownerId: _currentUser!,
        ),
        CategoryModel(id: 'c-others', name: 'Lainnya', ownerId: _currentUser!),
      ]);
      await _persistCategories();
    }
    
    notifyListeners();
  }

  // ---------- queries ----------
  List<Expense> visibleExpenses() {
    if (_currentUser == null) return [];
    return _expenses
        .where(
          (e) =>
              e.ownerId == _currentUser || e.sharedWith.contains(_currentUser),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ---------- CRUD expenses ----------
  Future<void> addExpense(Expense e) async {
    _expenses.add(e);
    await _persistExpenses();
    notifyListeners();
  }

  Future<void> updateExpense(Expense e) async {
    final idx = _expenses.indexWhere((x) => x.id == e.id);
    if (idx != -1) {
      _expenses[idx] = e;
      await _persistExpenses();
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _persistExpenses();
    notifyListeners();
  }

  // ---------- CRUD categories ----------
  Future<void> addCategory(CategoryModel c) async {
    _categories.add(c);
    await _persistCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await _persistCategories();
    notifyListeners();
  }

  CategoryModel? getCategory(String id) => _categories.firstWhere(
    (c) => c.id == id,
    orElse: () => CategoryModel(id: id, name: 'Unknown', ownerId: 'global'),
  );
}
