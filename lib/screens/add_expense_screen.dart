import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/currency_utils.dart';
import '../utils/date_utils.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _form = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _amountC = TextEditingController();
  final _descC = TextEditingController();
  DateTime _date = DateTime.now();
  String? _categoryId;

  @override
  void dispose() {
    _titleC.dispose();
    _amountC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final svc = context.read<ExpenseService>();
    final userId = svc.currentUser;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User belum ter-set')));
      return;
    }

    final amt = CurrencyUtils.parse(_amountC.text);
    final expense = Expense(
      id: const Uuid().v4(),
      ownerId: userId,
      title: _titleC.text.trim(),
      amount: amt,
      category: _categoryId ?? 'Lainnya',
      date: _date,
      description: _descC.text.trim(),
      sharedWith: const [],
    );

    await svc.addExpense(expense);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pengeluaran ditambahkan')));
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ExpenseService>();
    final userId = svc.currentUser;
    // kategori yang boleh dipakai: global atau milik user aktif
    final categories =
        svc.categories
            .where((c) => c.ownerId == 'global' || c.ownerId == userId)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Pengeluaran')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleC,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  hintText: 'cth: Makan siang',
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Judul wajib diisi'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  hintText: 'cth: 25000',
                ),
                validator:
                    (v) =>
                        (CurrencyUtils.parse(v ?? '') <= 0)
                            ? 'Nominal tidak valid'
                            : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                items:
                    categories
                        .map(
                          (c) => DropdownMenuItem(
                            value:
                                c.name, // kita simpan pakai name sebagai id kategori sederhana
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                decoration: const InputDecoration(labelText: 'Kategori'),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal'),
                subtitle: Text(AppDateUtils.dmy(_date)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descC,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
