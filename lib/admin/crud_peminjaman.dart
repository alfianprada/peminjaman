import 'package:flutter/material.dart';

class CrudPeminjamanPage extends StatelessWidget {
  const CrudPeminjamanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Peminjaman')),
      body: const Center(child: Text('Data peminjaman alat')),
    );
  }
}
