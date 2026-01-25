import 'package:flutter/material.dart';

class CrudPengembalianPage extends StatelessWidget {
  const CrudPengembalianPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Pengembalian')),
      body: const Center(child: Text('Data pengembalian alat')),
    );
  }
}
