import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../services/expense_service.dart';
import '../models/category.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ExpenseService>();
    final currentUser = svc.currentUser;

    // pisahkan kategori global vs milik user
    final globalCats =
        svc.categories.where((c) => c.ownerId == 'global').toList();
    final myCats =
        svc.categories.where((c) => c.ownerId == currentUser).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: [
          const _SectionHeader(title: 'Global'),
          if (globalCats.isEmpty)
            const _Empty('Belum ada kategori global')
          else
            ...globalCats.map(
              (c) =>
                  _CategoryTile(category: c, canDelete: false, onDelete: null),
            ),

          const SizedBox(height: 12),
          const _SectionHeader(title: 'Milik Anda'),
          if (myCats.isEmpty)
            const _Empty('Belum ada kategori milik Anda')
          else
            ...myCats.map(
              (c) => _CategoryTile(
                category: c,
                canDelete: true,
                onDelete: () => svc.deleteCategory(c.id),
              ),
            ),
        ],
      ),

      // Tambah kategori
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await _showAddDialog(context);
          if (name == null || name.trim().isEmpty) return;

          final id = const Uuid().v4();
          final newCat = CategoryModel(
            id: id,
            name: name.trim(),
            ownerId: currentUser ?? 'user-unknown',
          );
          await svc.addCategory(newCat);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kategori ditambahkan')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Kategori Baru'),
      ),
    );
  }

  // dialog input nama kategori
  Future<String?> _showAddDialog(BuildContext context) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Kategori Baru'),
            content: TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Mis. Makanan, Transportasi',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, c.text),
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.blueGrey[700],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey[600])),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final bool canDelete;
  final VoidCallback? onDelete;

  const _CategoryTile({
    required this.category,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.label_outline),
        title: Text(category.name),
        subtitle: Text(
          category.ownerId == 'global' ? 'Global' : 'Milik Anda',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing:
            canDelete
                ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Hapus',
                )
                : null,
      ),
    );
  }
}
