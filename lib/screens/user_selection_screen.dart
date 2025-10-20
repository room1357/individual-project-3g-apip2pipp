import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/shared_expense_service.dart';

class UserSelectionScreen extends StatefulWidget {
  final List<String>? initialSelectedUsers;
  
  const UserSelectionScreen({
    super.key,
    this.initialSelectedUsers,
  });

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final Set<String> _selectedUsers = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedUsers != null) {
      _selectedUsers.addAll(widget.initialSelectedUsers!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharedExpenseService = context.read<SharedExpenseService>();
    final availableUsers = sharedExpenseService.getAvailableUsers();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih User'),
        actions: [
          TextButton(
            onPressed: _selectedUsers.isEmpty 
                ? null 
                : () => Navigator.pop(context, _selectedUsers.toList()),
            child: const Text('Pilih'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pilih user yang akan berbagi pengeluaran ini',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Selected users count
          if (_selectedUsers.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${_selectedUsers.length} user dipilih',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          // Users list
          Expanded(
            child: availableUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada user lain',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Buat akun lain untuk berbagi pengeluaran',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: availableUsers.length,
                    itemBuilder: (context, index) {
                      final userEmail = availableUsers[index];
                      final userName = sharedExpenseService.getUserDisplayName(userEmail);
                      final isSelected = _selectedUsers.contains(userEmail);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedUsers.add(userEmail);
                              } else {
                                _selectedUsers.remove(userEmail);
                              }
                            });
                          },
                          title: Text(
                            userName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            userEmail,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.person,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
