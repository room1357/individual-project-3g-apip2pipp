import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/shared_expense_service.dart';
import '../services/auth_service.dart';
import '../models/expense.dart';
import 'add_shared_expense_screen.dart';

class SharedExpenseScreen extends StatefulWidget {
  const SharedExpenseScreen({super.key});

  @override
  State<SharedExpenseScreen> createState() => _SharedExpenseScreenState();
}

class _SharedExpenseScreenState extends State<SharedExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Expenses'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semua', icon: Icon(Icons.list)),
            Tab(text: 'Saya Buat', icon: Icon(Icons.person_add)),
            Tab(text: 'Dibagikan', icon: Icon(Icons.people)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddSharedExpenseScreen(),
              ),
            ),
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Shared Expense',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllSharedExpensesTab(),
          _MySharedExpensesTab(),
          _SharedWithMeTab(),
        ],
      ),
    );
  }
}

class _AllSharedExpensesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SharedExpenseService>(
      builder: (context, sharedExpenseService, child) {
        final expenses = sharedExpenseService.sharedExpenses;
        
        if (expenses.isEmpty) {
          return _EmptyState(
            icon: Icons.share,
            title: 'Belum ada Shared Expenses',
            subtitle: 'Mulai berbagi pengeluaran dengan user lain',
            actionText: 'Tambah Shared Expense',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddSharedExpenseScreen(),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _SharedExpenseCard(expense: expense);
          },
        );
      },
    );
  }
}

class _MySharedExpensesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SharedExpenseService>(
      builder: (context, sharedExpenseService, child) {
        final expenses = sharedExpenseService.mySharedExpenses;
        
        if (expenses.isEmpty) {
          return _EmptyState(
            icon: Icons.person_add,
            title: 'Belum ada Shared Expenses yang Anda buat',
            subtitle: 'Buat shared expense untuk berbagi dengan user lain',
            actionText: 'Tambah Shared Expense',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddSharedExpenseScreen(),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _SharedExpenseCard(expense: expense);
          },
        );
      },
    );
  }
}

class _SharedWithMeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SharedExpenseService>(
      builder: (context, sharedExpenseService, child) {
        final expenses = sharedExpenseService.sharedWithMe;
        
        if (expenses.isEmpty) {
          return _EmptyState(
            icon: Icons.people,
            title: 'Belum ada Shared Expenses yang dibagikan kepada Anda',
            subtitle: 'User lain akan membagikan pengeluaran kepada Anda',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _SharedExpenseCard(expense: expense);
          },
        );
      },
    );
  }
}

class _SharedExpenseCard extends StatelessWidget {
  final Expense expense;

  const _SharedExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sharedExpenseService = context.read<SharedExpenseService>();
    final authService = context.read<AuthService>();
    
    final isOwner = expense.ownerId == authService.currentUserEmail;
    final sharedAmount = sharedExpenseService.calculateSharedAmount(expense);
    final splitAmounts = sharedExpenseService.calculateSplitAmounts(expense);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    expense.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOwner ? cs.primary : cs.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOwner ? 'Owner' : 'Shared',
                    style: TextStyle(
                      color: isOwner ? cs.onPrimary : cs.onSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Amount info
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: cs.primary),
                const SizedBox(width: 4),
                Text(
                  'Total: ${expense.formattedAmount}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Bagian Anda: Rp ${sharedAmount.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Category and date
            Row(
              children: [
                Icon(Icons.category, size: 16, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  expense.category,
                  style: TextStyle(color: cs.outline),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  expense.formattedDate,
                  style: TextStyle(color: cs.outline),
                ),
              ],
            ),
            
            if (expense.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                expense.description,
                style: TextStyle(color: cs.outline),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Shared users
            Row(
              children: [
                Icon(Icons.people, size: 16, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  'Dibagikan dengan ${expense.sharedWith.length} user',
                  style: TextStyle(color: cs.outline),
                ),
              ],
            ),
            
            // Split amounts
            if (splitAmounts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembagian:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...splitAmounts.entries.map((entry) {
                      final isCurrentUser = entry.key == authService.currentUserEmail;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              isCurrentUser ? 'Anda' : sharedExpenseService.getUserDisplayName(entry.key),
                              style: TextStyle(
                                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                color: isCurrentUser ? cs.primary : null,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Rp ${entry.value.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                color: isCurrentUser ? cs.primary : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: cs.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
