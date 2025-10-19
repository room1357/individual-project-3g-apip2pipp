import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPassC = TextEditingController();
  final _newPassC = TextEditingController();
  final _confirmPassC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentPassC.dispose();
    _newPassC.dispose();
    _confirmPassC.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().changePassword(
        currentPassword: _currentPassC.text,
        newPassword: _newPassC.text,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah password: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganti Password'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _changePassword,
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
              // Info card
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Password harus minimal 6 karakter dan mengandung huruf serta angka',
                          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Current password
              TextFormField(
                controller: _currentPassC,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Password Lama',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Password lama wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // New password
              TextFormField(
                controller: _newPassC,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Password baru wajib diisi';
                  }
                  if (v.length < 6) {
                    return 'Minimal 6 karakter';
                  }
                  if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(v)) {
                    return 'Harus mengandung huruf dan angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Confirm password
              TextFormField(
                controller: _confirmPassC,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Konfirmasi password wajib diisi';
                  }
                  if (v != _newPassC.text) {
                    return 'Password tidak sama';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Action button
              FilledButton.icon(
                onPressed: _loading ? null : _changePassword,
                icon: const Icon(Icons.security),
                label: const Text('Ubah Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
