// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/currency_utils.dart';
import '../utils/date_utils.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;
  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _titleC;
  late TextEditingController _amountC;
  late TextEditingController _descC;
  late DateTime _date;
  String? _category;

  @override
  void initState() {
    super.initState();
    _titleC = TextEditingController(text: widget.expense.title);
    _amountC = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(0),
    );
    _descC = TextEditingController(text: widget.expense.description);
    _date = widget.expense.date;
    _category = widget.expense.category;
  }

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

    final updated = widget.expense.copyWith(
      title: _titleC.text.trim(),
      amount: CurrencyUtils.parse(_amountC.text),
      category: _category ?? widget.expense.category,
      date: _date,
      description: _descC.text.trim(),
    );

    await svc.updateExpense(updated);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hapus pengeluaran?'),
            content: const Text('Tindakan ini tidak bisa dibatalkan.'),
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
    if (ok != true) return;

    final svc = context.read<ExpenseService>();
    await svc.deleteExpense(widget.expense.id);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pengeluaran dihapus')));
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ExpenseService>();
    final currentUser = svc.currentUser;
    final isOwner = currentUser == widget.expense.ownerId;

    final categories =
        svc.categories
            .where((c) => c.ownerId == 'global' || c.ownerId == currentUser)
            .map((c) => c.name)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pengeluaran'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus',
              onPressed: _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleC,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                validator:
                    (v) =>
                        (CurrencyUtils.parse(v ?? '') <= 0)
                            ? 'Nominal tidak valid'
                            : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items:
                    categories
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _category = v),
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
                label: const Text('Simpan Perubahan'),
              ),
              if (!isOwner) ...[
                const SizedBox(height: 8),
                const Text(
                  'Catatan: Anda bukan pemilik, jadi tidak bisa menghapus item ini.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
