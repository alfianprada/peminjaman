import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrudKategoriPage extends StatefulWidget {
  const CrudKategoriPage({super.key});

  @override
  State<CrudKategoriPage> createState() => _CrudKategoriPageState();
}

class _CrudKategoriPageState extends State<CrudKategoriPage> {
  final supabase = Supabase.instance.client;

  // ================= GET KATEGORI =================
  Future<List<dynamic>> _getKategori() async {
    return await supabase
        .from('kategori')
        .select()
        .order('nama_kategori');
  }

  // ================= TAMBAH / EDIT =================
  void _formKategori({Map? kategori}) {
    final namaC =
        TextEditingController(text: kategori?['nama_kategori']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(kategori == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: namaC,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            child: const Text('SIMPAN'),
            onPressed: () async {
              if (namaC.text.isEmpty) return;

              if (kategori == null) {
                await supabase.from('kategori').insert({
                  'nama_kategori': namaC.text,
                });
              } else {
                await supabase
                    .from('kategori')
                    .update({'nama_kategori': namaC.text})
                    .eq('id', kategori['id']);
              }

              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // ================= HAPUS =================
  void _hapusKategori(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text(
            'Kategori ini akan dihapus. Pastikan tidak sedang digunakan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await supabase.from('kategori').delete().eq('id', id);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Manajemen Kategori',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: FutureBuilder<List<dynamic>>(
        future: _getKategori(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final kategori = snapshot.data!;
          if (kategori.isEmpty) {
            return const Center(child: Text('Belum ada kategori'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kategori.length,
            itemBuilder: (context, i) {
              final k = kategori[i];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.category),
                  ),
                  title: Text(
                    k['nama_kategori'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') _formKategori(kategori: k);
                      if (v == 'delete') _hapusKategori(k['id']);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formKategori(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori'),
      ),
    );
  }
}
