// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/currency_utils.dart';
import '../utils/date_utils.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';

import '../services/pdf_export_service.dart';
import 'package:printing/printing.dart';

enum SortMode { dateDesc, dateAsc, amountDesc, amountAsc }

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  // ---- state filter/sort/search (dari Lat 3) ----
  String _query = '';
  String? _selectedCategory; // null = all
  SortMode _sort = SortMode.dateDesc;
  final _searchC = TextEditingController();

  // ---- state advanced (Lat 4) ----
  final Set<String> _selected = {}; // multi-select
  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ExpenseService>();
    final currentUser = svc.currentUser;

    // sumber data mentah
    final base = svc.visibleExpenses();

    // kategori untuk filter
    final categories =
        svc.categories
            .where((c) => c.ownerId == 'global' || c.ownerId == currentUser)
            .map((c) => c.name)
            .toList();

    // ====== FILTER / SEARCH / SORT (Lat 3) ======
    List<Expense> list =
        _selectedCategory == null
            ? List.of(base)
            : base.where((e) => e.category == _selectedCategory).toList();

    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list =
          list
              .where(
                (e) =>
                    e.title.toLowerCase().contains(q) ||
                    e.description.toLowerCase().contains(q),
              )
              .toList();
    }

    list.sort((a, b) {
      switch (_sort) {
        case SortMode.dateDesc:
          return b.date.compareTo(a.date);
        case SortMode.dateAsc:
          return a.date.compareTo(b.date);
        case SortMode.amountDesc:
          return b.amount.compareTo(a.amount);
        case SortMode.amountAsc:
          return a.amount.compareTo(b.amount);
      }
    });

    // total
    final total = list.fold<double>(0.0, (s, e) => s + e.amount);

    // ====== GROUP BY TANGGAL (header per hari) ======
    final items = _buildSectioned(list);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectionMode ? '${_selected.length} dipilih' : 'Daftar Pengeluaran',
        ),
        backgroundColor: _selectionMode ? Colors.indigo : Colors.blue,
        actions:
            _selectionMode
                ? [
                  IconButton(
                    tooltip: 'Pilih semua',
                    icon: const Icon(Icons.select_all),
                    onPressed: () {
                      setState(() {
                        _selected
                          ..clear()
                          ..addAll(list.map((e) => e.id));
                      });
                    },
                  ),
                  IconButton(
                    tooltip: 'Hapus yang dipilih',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await _confirmDeleteMany(
                        context,
                        _selected.length,
                      );
                      if (ok != true) return;
                      final ids = _selected.toList();
                      _selected.clear();
                      for (final id in ids) {
                        await context.read<ExpenseService>().deleteExpense(id);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${ids.length} item dihapus')),
                        );
                        setState(() {});
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Batal',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selected.clear()),
                  ),
                ]
                : [
                  // === tombol-tombol saat TIDAK selection mode ===
                  IconButton(
                    tooltip: 'Kelola Kategori',
                    icon: const Icon(Icons.category_outlined),
                    onPressed:
                        () => Navigator.pushNamed(context, '/categories'),
                  ),

                  IconButton(
                    tooltip: 'Statistik',
                    icon: const Icon(Icons.insights_outlined),
                    onPressed: () => Navigator.pushNamed(context, '/stats'),
                  ),

                  IconButton(
                    tooltip: 'Export PDF',
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () async {
                      if (list.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tidak ada data untuk diekspor'),
                          ),
                        );
                        return;
                      }
                      // list = hasil filter/sort yang kamu hitung di atas
                      final bytes = await PdfExportService.buildPdfBytes(list);
                      // langsung buka share sheet (bisa kirim ke WhatsApp, Google Drive, dll.)
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: 'expenses.pdf',
                      );

                      // Alternatif: preview dulu
                      // await Printing.layoutPdf(onLayout: (_) => PdfExportService.buildPdfBytes(list));

                      // Alternatif: simpan file lalu share_plus
                      // final file = await PdfExportService.savePdfTemp(list);
                      // await Share.shareXFiles([XFile(file.path)], text: 'Laporan pengeluaran');
                    },
                  ),
                ],

        bottom:
            !_selectionMode
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(68),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: _FilterBar(
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged:
                          (v) => setState(() => _selectedCategory = v),
                      searchController: _searchC,
                      onSearchChanged: (v) => setState(() => _query = v),
                      sortMode: _sort,
                      onChangeSort: (v) => setState(() => _sort = v),
                    ),
                  ),
                )
                : null,
      ),

      // PULL TO REFRESH
      body: RefreshIndicator(
        onRefresh: () async {
          // simulasi refresh (data lokal), kalau ada sumber remote tinggal panggil fetch
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) setState(() {});
        },
        child: Column(
          children: [
            // Header total
            if (!_selectionMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Pengeluaran',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    Text(
                      CurrencyUtils.format(total),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

            // List sectioned
            Expanded(
              child:
                  items.isEmpty
                      ? const Center(child: Text('Tidak ada data'))
                      : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final it = items[i];
                          if (it.isHeader) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                              child: Text(
                                AppDateUtils.dmy(it.date!),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blueGrey[700],
                                ),
                              ),
                            );
                          }
                          final e = it.expense!;
                          final checked = _selected.contains(e.id);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            elevation: checked ? 6 : 2,
                            child: ListTile(
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _getCategoryColor(
                                      e.category,
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(e.category),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  if (checked)
                                    const Positioned.fill(
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                e.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                e.category,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Text(
                                CurrencyUtils.format(e.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red[600],
                                ),
                              ),

                              // TAP = edit (kalau tidak sedang select mode), kalau sedang select: toggle
                              onTap: () {
                                if (_selectionMode) {
                                  setState(() {
                                    if (checked) {
                                      _selected.remove(e.id);
                                    } else {
                                      _selected.add(e.id);
                                    }
                                  });
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EditExpenseScreen(expense: e),
                                  ),
                                );
                              },

                              // LONG PRESS = masuk/keluar pilih
                              onLongPress: () {
                                setState(() {
                                  if (checked) {
                                    _selected.remove(e.id);
                                  } else {
                                    _selected.add(e.id);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),

      // Tambah
      floatingActionButton:
          _selectionMode
              ? null
              : FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                  );
                },
                backgroundColor: Colors.blue,
                child: const Icon(Icons.add),
              ),
    );
  }

  Future<bool?> _confirmDeleteMany(BuildContext context, int n) {
    return showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hapus data terpilih?'),
            content: Text('$n item akan dihapus dan tidak bisa dikembalikan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  // Section builder: header tanggal + item
  List<_SectionItem> _buildSectioned(List<Expense> list) {
    final items = <_SectionItem>[];
    DateTime? last;
    for (final e in list) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (last == null || d.difference(last).inDays != 0) {
        items.add(_SectionItem.header(d));
        last = d;
      }
      items.add(_SectionItem.item(e));
    }
    return items;
  }

  // Warna kategori
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return Colors.orange;
      case 'transportasi':
        return Colors.green;
      case 'utilitas':
        return Colors.purple;
      case 'hiburan':
        return Colors.pink;
      case 'pendidikan':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Icon kategori
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return Icons.restaurant;
      case 'transportasi':
        return Icons.directions_car;
      case 'utilitas':
        return Icons.home;
      case 'hiburan':
        return Icons.movie;
      case 'pendidikan':
        return Icons.school;
      default:
        return Icons.attach_money;
    }
  }
}

class _SectionItem {
  final bool isHeader;
  final DateTime? date;
  final Expense? expense;
  _SectionItem.header(this.date) : isHeader = true, expense = null;
  _SectionItem.item(this.expense) : isHeader = false, date = null;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.searchController,
    required this.onSearchChanged,
    required this.sortMode,
    required this.onChangeSort,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  final SortMode sortMode;
  final ValueChanged<SortMode> onChangeSort;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            isExpanded: true,
            hint: const Text('Semua Kategori'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua Kategori'),
              ),
              ...categories.map(
                (name) =>
                    DropdownMenuItem<String>(value: name, child: Text(name)),
              ),
            ],
            onChanged: onCategoryChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Cari judul/desk...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<SortMode>(
          tooltip: 'Urutkan',
          icon: const Icon(Icons.sort),
          onSelected: onChangeSort,
          itemBuilder:
              (context) => const [
                PopupMenuItem(
                  value: SortMode.dateDesc,
                  child: Text('Tanggal terbaru'),
                ),
                PopupMenuItem(
                  value: SortMode.dateAsc,
                  child: Text('Tanggal terlama'),
                ),
                PopupMenuItem(
                  value: SortMode.amountDesc,
                  child: Text('Nominal terbesar'),
                ),
                PopupMenuItem(
                  value: SortMode.amountAsc,
                  child: Text('Nominal terkecil'),
                ),
              ],
        ),
      ],
    );
  }
}
