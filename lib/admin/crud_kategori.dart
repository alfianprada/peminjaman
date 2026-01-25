import 'package:flutter/material.dart';

class CrudKategoriPage extends StatelessWidget {
  const CrudKategoriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Kategori')),
      body: const Center(child: Text('Data kategori alat')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
