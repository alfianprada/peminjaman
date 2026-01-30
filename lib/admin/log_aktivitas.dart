import 'package:flutter/material.dart';

class LogAktivitasPage extends StatelessWidget {
  const LogAktivitasPage({super.key, required String role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Aktivitas')),
      body: const Center(
        child: Text('Log aktivitas admin, petugas, peminjam'),
      ),
    );
  }
}
