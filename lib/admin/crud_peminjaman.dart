import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrudPeminjamanAdminPage extends StatefulWidget {
  const CrudPeminjamanAdminPage({super.key});

  @override
  State<CrudPeminjamanAdminPage> createState() =>
      _CrudPeminjamanAdminPageState();
}

class _CrudPeminjamanAdminPageState extends State<CrudPeminjamanAdminPage> {
  final supabase = Supabase.instance.client;
  String _statusFilter = 'all';

  Future<List<dynamic>> fetchPeminjaman() async {
  var query = supabase
  .from('peminjaman')
  .select('''
    id,
    nama,
    no_telepon,
    tanggal_pinjam,
    tanggal_kembali_rencana,
    status,
    detail_peminjaman!detail_peminjaman_peminjaman_id_fkey (
      jumlah,
      alat!detail_peminjaman_alat_id_fkey (
        nama_alat
      )
    )
  ''');


  if (_statusFilter != 'all') {
    query.eq('status', _statusFilter);
  }

  final data = await query.order(
    'tanggal_pinjam',
    ascending: false,
  );

  return data;
}

  Future<void> hapusPeminjaman(int id) async {
    await supabase.from('peminjaman').delete().eq('id', id);

    await supabase.from('log_aktivitas').insert({
      'user_id': supabase.auth.currentUser!.id,
      'role': 'admin',
      'aktivitas': 'Menghapus data peminjaman',
      'peminjaman_id': id,
    });

  // hapus pengembalian dulu
  await supabase.from('pengembalian')
      .delete()
      .eq('peminjaman_id', id);

  // hapus detail
  await supabase.from('detail_peminjaman')
      .delete()
      .eq('peminjaman_id', id);

  // baru hapus peminjaman
  await supabase.from('peminjaman')
      .delete()
      .eq('id', id);


    setState(() {});
  }

  Color warnaStatus(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'disetujui':
        return Colors.blue;
      case 'selesai':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD Peminjaman (Admin)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// FILTER STATUS
            DropdownButtonFormField<String>(
              value: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Filter Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(
                    value: 'disetujui', child: Text('Disetujui')),
                DropdownMenuItem(
                    value: 'selesai', child: Text('Selesai')),
                DropdownMenuItem(
                    value: 'ditolak', child: Text('Ditolak')),
              ],
              onChanged: (v) {
                setState(() => _statusFilter = v!);
              },
            ),

            const SizedBox(height: 12),

            /// LIST PEMINJAMAN
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: fetchPeminjaman(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('Data peminjaman kosong'));
                  }

                  final data = snapshot.data!;

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final p = data[index];
                      final List details = p['detail_peminjaman'] ?? [];
print(p);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['nama']?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text('Telp: ${p['no_telepon'] ?? '-'}'),
                              Text(
  'Pinjam: ${p['tanggal_pinjam'] != null
      ? p['tanggal_pinjam'].toString().substring(0, 10)
      : '-'}',
),

Text(
  'Kembali: ${p['tanggal_kembali_rencana'] != null
      ? p['tanggal_kembali_rencana'].toString().substring(0, 10)
      : '-'}',
),

                              const SizedBox(height: 6),

                              Chip(
  label: Text(
    (p['status'] ?? '-').toString().toUpperCase(),
  ),
  backgroundColor: warnaStatus(p['status'] ?? ''),
),

                              const Divider(),

ExpansionTile(
  title: const Text('Detail Alat'),
  children: details.isEmpty
      ? [
          const ListTile(
            title: Text(
              'Belum ada detail alat',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        ]
      : details.map<Widget>((d) {
          final alat = d['alat'];

          if (alat == null) {
            return const ListTile(
              title: Text('Data alat tidak tersedia'),
            );
          }

          return ListTile(
            leading: const Icon(Icons.build),
            title: Text(alat['nama_alat'] ?? '-'),
            trailing: Text('x${d['jumlah'] ?? 0}'),
          );
        }).toList(),
),


                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        hapusPeminjaman(p['id']),
                                  ),
                                ],
                              )
                            ],
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
    );
  }
}
