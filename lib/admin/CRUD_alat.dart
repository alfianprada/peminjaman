import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrudAlatPage extends StatefulWidget {
  const CrudAlatPage({super.key});

  @override
  State<CrudAlatPage> createState() => _CrudAlatPageState();
}

class _CrudAlatPageState extends State<CrudAlatPage> {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> _getAlat() async {
    return await supabase
        .from('alat')
        .select('*, kategori(nama_kategori)')
        .order('nama_alat');
  }

  Future<List<dynamic>> _getKategori() async {
    return await supabase.from('kategori').select();
  }

  // ================= TAMBAH / EDIT =================
  void _formAlat({Map? alat}) async {
    final namaC = TextEditingController(text: alat?['nama_alat']);
    final stokC =
        TextEditingController(text: alat != null ? '${alat['stok']}' : '');
    final lokasiC = TextEditingController(text: alat?['lokasi']);
    String kondisi = alat?['kondisi'] ?? 'baik';
    int? kategoriId = alat?['kategori_id'];

    final kategori = await _getKategori();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(alat == null ? 'Tambah Alat' : 'Edit Alat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaC,
                decoration: const InputDecoration(labelText: 'Nama Alat'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: kategoriId,
                items: kategori
    .map<DropdownMenuItem<int>>(
      (k) => DropdownMenuItem<int>(
        value: k['id'] as int,
        child: Text(k['nama_kategori']),
      ),
    )
    .toList(),
                onChanged: (v) => kategoriId = v,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stokC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: kondisi,
                items: const [
                  DropdownMenuItem(value: 'baik', child: Text('Baik')),
                  DropdownMenuItem(value: 'rusak', child: Text('Rusak')),
                ],
                onChanged: (v) => kondisi = v!,
                decoration: const InputDecoration(labelText: 'Kondisi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lokasiC,
                decoration: const InputDecoration(labelText: 'Lokasi'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            child: const Text('SIMPAN'),
            onPressed: () async {
              final data = {
                'nama_alat': namaC.text,
                'kategori_id': kategoriId,
                'stok': int.parse(stokC.text),
                'kondisi': kondisi,
                'lokasi': lokasiC.text,
              };

              if (alat == null) {
                await supabase.from('alat').insert(data);
              } else {
                await supabase
                    .from('alat')
                    .update(data)
                    .eq('id', alat['id']);
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
  void _hapusAlat(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Alat'),
        content: const Text('Yakin ingin menghapus alat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('HAPUS'),
            onPressed: () async {
              await supabase.from('alat').delete().eq('id', id);
              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Color _stokColor(int stok) {
    if (stok == 0) return Colors.red;
    if (stok <= 2) return Colors.orange;
    return Colors.green;
  }

    @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFE0E0E0),
    body: SafeArea(
      child: Column(
        children: [
          // ===== HEADER (SAMA SEPERTI PROFILE ADMIN) =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Manajemen Alat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ===== CONTENT =====
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _getAlat(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final alat = snapshot.data!;
                if (alat.isEmpty) {
                  return const Center(child: Text('Belum ada alat'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alat.length,
                  itemBuilder: (context, i) {
                    final a = alat[i];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _stokColor(a['stok']).withOpacity(0.15),
                          child: Icon(
                            Icons.build,
                            color: _stokColor(a['stok']),
                          ),
                        ),
                        title: Text(
                          a['nama_alat'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kategori: ${a['kategori']?['nama_kategori'] ?? '-'}',
                            ),
                            Text('Lokasi: ${a['lokasi'] ?? '-'}'),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(
                                'Stok: ${a['stok']}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: _stokColor(a['stok']),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Hapus')),
                          ],
                          onSelected: (v) {
                            if (v == 'edit') _formAlat(alat: a);
                            if (v == 'delete') _hapusAlat(a['id']);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),

    // ===== FAB =====
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: const Color(0xFF1976D2),
      onPressed: () => _formAlat(),
      icon: const Icon(Icons.add),
      label: const Text('Tambah Alat'),
    ),
  );
}

  }

