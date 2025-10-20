import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/shared_expense_service.dart';
import '../services/expense_service.dart';
import '../models/expense.dart';
import 'user_selection_screen.dart';

class AddSharedExpenseScreen extends StatefulWidget {
  const AddSharedExpenseScreen({super.key});

  @override
  State<AddSharedExpenseScreen> createState() => _AddSharedExpenseScreenState();
}

class _AddSharedExpenseScreenState extends State<AddSharedExpenseScreen> {
  final _titleC = TextEditingController();
  final _amountC = TextEditingController();
  final _descriptionC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  List<String> _selectedUsers = [];
  bool _loading = false;

  @override
  void dispose() {
    _titleC.dispose();
    _amountC.dispose();
    _descriptionC.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectUsers() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => UserSelectionScreen(initialSelectedUsers: _selectedUsers),
      ),
    );
    
    if (result != null) {
      setState(() => _selectedUsers = result);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu user untuk berbagi')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<SharedExpenseService>().createSharedExpense(
        title: _titleC.text,
        amount: double.parse(_amountC.text),
        category: _selectedCategory!,
        date: _selectedDate,
        description: _descriptionC.text,
        sharedWithUserIds: _selectedUsers,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared expense berhasil dibuat')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat shared expense: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final expenseService = context.watch<ExpenseService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Shared Expense'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveExpense,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleC,
                decoration: const InputDecoration(
                  labelText: 'Judul Pengeluaran',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Judul wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Amount
              TextFormField(
                controller: _amountC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Jumlah wajib diisi';
                  }
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) {
                    return 'Jumlah harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: expenseService.categories
                    .map((category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),
              
              // Date
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionC,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              // Shared users section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Berbagi dengan',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (_selectedUsers.isEmpty)
                        Text(
                          'Belum ada user dipilih',
                          style: TextStyle(color: cs.outline),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedUsers.map((userEmail) {
                            final sharedExpenseService = context.read<SharedExpenseService>();
                            final userName = sharedExpenseService.getUserDisplayName(userEmail);
                            return Chip(
                              label: Text(userName),
                              onDeleted: () {
                                setState(() => _selectedUsers.remove(userEmail));
                              },
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _selectUsers,
                          icon: const Icon(Icons.add),
                          label: Text(_selectedUsers.isEmpty ? 'Pilih User' : 'Ubah User'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Save button
              FilledButton.icon(
                onPressed: _loading ? null : _saveExpense,
                icon: const Icon(Icons.save),
                label: const Text('Buat Shared Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
