import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;
  bool _confirmDelete = false;

  @override
  void dispose() {
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_confirmDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Centang konfirmasi untuk melanjutkan')),
      );
      return;
    }
    
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().deleteAccount(
        password: _passwordC.text,
      );
      
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus akun: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hapus Akun'),
        backgroundColor: cs.error,
        foregroundColor: cs.onError,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning card
              Card(
                color: cs.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning,
                        color: cs.onErrorContainer,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'PERINGATAN',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: cs.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tindakan ini tidak dapat dibatalkan. Semua data pengeluaran dan informasi akun akan dihapus secara permanen.',
                        style: TextStyle(color: cs.onErrorContainer),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Password field
              TextFormField(
                controller: _passwordC,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Masukkan Password untuk Konfirmasi',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Password wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Confirmation checkbox
              Card(
                color: cs.surfaceVariant,
                child: CheckboxListTile(
                  value: _confirmDelete,
                  onChanged: (value) => setState(() => _confirmDelete = value ?? false),
                  title: const Text('Saya mengerti dan setuju untuk menghapus akun'),
                  subtitle: const Text('Semua data akan hilang permanen'),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              FilledButton.icon(
                onPressed: _loading ? null : _deleteAccount,
                icon: const Icon(Icons.delete_forever),
                label: const Text('HAPUS AKUN'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
              ),
              const SizedBox(height: 12),
              
              OutlinedButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
