import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Aplikasi Pengeluaran\n'
          'Versi 1.0.0\n\n',

          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
