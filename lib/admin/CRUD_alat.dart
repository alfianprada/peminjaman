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
String formatRupiah(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  int count = 0;

  for (int i = s.length - 1; i >= 0; i--) {
    buffer.write(s[i]);
    count++;
    if (count == 3 && i != 0) {
      buffer.write('.');
      count = 0;
    }
  }

  return 'Rp.${buffer.toString().split('').reversed.join()}.00';
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
bool isValidRupiah(String value) {
  final regex = RegExp(r'^Rp\.\d{1,3}(\.\d{3})*.\d{2}$');
  return regex.hasMatch(value);
}

int rupiahToInt(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.parse(digits) ~/ 100;
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

    final dendaC = TextEditingController(
  text: alat != null ? '${alat['denda_per_hari'] ?? 0}' : '',
);


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
                  onChanged: (v) {
  setState(() {
    kategoriId = v;
  });
},

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

                // ===== DENDA =====
TextField(
  controller: dendaC,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    labelText: 'Denda per Hari (Rp)',
    hintText: 'Rp.1.000.00',
    prefixIcon: const Icon(Icons.payments),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
const SizedBox(height: 14),


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
    dendaC.text.isEmpty ||
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

// 🔴 VALIDASI FORMAT RUPIAH
if (!isValidRupiah(dendaC.text)) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Format denda harus Rp.xxx.xxx.00'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}



                          final data = {
  'nama_alat': namaC.text,
  'kategori_id': kategoriId,
  'stok': int.parse(stokC.text),
  'denda_per_hari': rupiahToInt(dendaC.text),
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
      appBar: PreferredSize(
  preferredSize: const Size.fromHeight(90),// tinggi AppBar
  child: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 4, // 👈 INI YANG BIKIN TURUN
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),

            const SizedBox(width: 10),

            // 🧰 LOGO APLIKASI
            Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 65,
                height: 65,
                fit: BoxFit.contain,
                // hapus kalau logo berwarna
              ),
            ),

            const SizedBox(width: 10),

            // 👤 NAMA + ROLE
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manajemen Alat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),


),
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
                    subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Kategori: ${a['kategori']?['nama_kategori'] ?? '-'}'),
    const SizedBox(height: 4),
    Row(
      children: [
        const Icon(Icons.inventory_2, size: 14),
        const SizedBox(width: 4),
        Text(
          'Stok: ${a['stok']} unit',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _stokColor(a['stok']),
          ),
        ),
      ],
    ),
    Text(
  'Denda: ${formatRupiah(a['denda_per_hari'] ?? 0)} / hari',
  style: const TextStyle(fontWeight: FontWeight.w500),
),
  ],
),  
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
