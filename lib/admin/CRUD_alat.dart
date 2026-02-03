import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peminjaman_alat/admin/drawer_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
final ImagePicker picker = ImagePicker();

class CrudAlatPage extends StatefulWidget {
  const CrudAlatPage({super.key});

  @override
  State<CrudAlatPage> createState() => _CrudAlatPageState();
}

class _CrudAlatPageState extends State<CrudAlatPage> {
  Uint8List? fotoBytes;
String? fotoAlatUrl;
String? fileExt;


  // ================= FOTO =================
  Future<void> pilihFoto() async {
  final XFile? picked =
      await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

  if (picked != null) {
    fotoBytes = await picked.readAsBytes();
    fileExt = picked.name.split('.').last;
    await uploadFotoAlat();
  }
}


 Future<void> uploadFotoAlat() async {
  if (fotoBytes == null) return;

  final fileName =
      'alat/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

  await supabase.storage.from('foto-alat').uploadBinary(
        fileName,
        fotoBytes!,
        fileOptions: const FileOptions(upsert: true),
      );

  fotoAlatUrl =
      supabase.storage.from('foto-alat').getPublicUrl(fileName);

  setState(() {});
}


  // ================= DATA =================
  Future<List<dynamic>> _getAlat() async {
    return await supabase
        .from('alat')
        .select('*, kategori(nama_kategori)')
        .eq('aktif', true)
        .order('nama_alat');
  }

  Future<List<dynamic>> _getKategori() async {
    return await supabase.from('kategori').select();
  }

  // ================= FORM =================
  void _formAlat({Map? alat}) async {
    final namaC = TextEditingController(text: alat?['nama_alat']);
    final stokC =
        TextEditingController(text: alat != null ? '${alat['stok']}' : '');
    final lokasiC = TextEditingController(text: alat?['lokasi']);

    String? kondisi = alat?['kondisi'];
    int? kategoriId = alat?['kategori_id'];
    fotoAlatUrl = alat?['foto_alat'];

    final kategoriList = await _getKategori();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alat == null ? 'Tambah Alat' : 'Edit Alat',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ===== FOTO =====
                InkWell(
                  onTap: pilihFoto,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: fotoAlatUrl == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.camera_alt, size: 40),
                              SizedBox(height: 8),
                              Text('Tambah Foto Alat'),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: fotoBytes != null
    ? Image.memory(fotoBytes!, fit: BoxFit.cover)
    : Image.network(fotoAlatUrl!)

                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ===== NAMA =====
                TextField(
                  controller: namaC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Alat',
                    prefixIcon: Icon(Icons.build),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // ===== KATEGORI =====
                DropdownButtonFormField<int>(
                  value: kategoriId,
                  hint: const Text('Pilih Kategori'),
                  items: kategoriList
                      .map<DropdownMenuItem<int>>(
                        (k) => DropdownMenuItem(
                          value: k['id'],
                          child: Text(k['nama_kategori']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => kategoriId = v,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // ===== KONDISI =====
                DropdownButtonFormField<String>(
                  value: kondisi,
                  hint: const Text('Pilih Kondisi'),
                  items: const [
                    DropdownMenuItem(value: 'Baik', child: Text('Baik')),
                    DropdownMenuItem(value: 'Rusak', child: Text('Rusak')),
                  ],
                  onChanged: (v) => kondisi = v,
                  decoration: const InputDecoration(
                    labelText: 'Kondisi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // ===== STOK =====
                TextField(
                  controller: stokC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stok',
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // ===== LOKASI =====
                TextField(
                  controller: lokasiC,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // ===== BUTTON =====
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('BATAL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (namaC.text.isEmpty ||
                              stokC.text.isEmpty ||
                              kategoriId == null ||
                              kondisi == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Semua field wajib diisi'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final data = {
                            'nama_alat': namaC.text,
                            'kategori_id': kategoriId,
                            'stok': int.parse(stokC.text),
                            'kondisi': kondisi,
                            'lokasi': lokasiC.text,
                            'foto_alat': fotoAlatUrl,
                          };

                          alat == null
                              ? await supabase.from('alat').insert(data)
                              : await supabase
                                  .from('alat')
                                  .update(data)
                                  .eq('id', alat['id']);

                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: const Text('SIMPAN'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _stokColor(int stok) =>
      stok == 0 ? Colors.red : stok <= 2 ? Colors.orange : Colors.green;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formAlat(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Alat'),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _getAlat(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final alat = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alat.length,
              itemBuilder: (_, i) {
                final a = alat[i];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: a['foto_alat'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              a['foto_alat'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.build,
                            color: _stokColor(a['stok'])),
                    title: Text(a['nama_alat']),
                    subtitle: Text(
                        'Kategori: ${a['kategori']?['nama_kategori'] ?? '-'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _formAlat(alat: a),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
