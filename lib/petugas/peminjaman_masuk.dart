import 'package:flutter/material.dart';
import 'package:peminjaman_alat/utils/log_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PeminjamanMasukPage extends StatefulWidget {
  const PeminjamanMasukPage({super.key});

  @override
  State<PeminjamanMasukPage> createState() => _PeminjamanMasukPageState();
}

class _PeminjamanMasukPageState extends State<PeminjamanMasukPage> {
  final supabase = Supabase.instance.client;

Future<List> fetchPeminjamanMasuk() async {
  final supabase = Supabase.instance.client;

  final res = await supabase
      .from('peminjaman')
      .select('''
        id,
        nama,
        tanggal_pinjam,
        status,
        detail_peminjaman (
          jumlah,
          alat ( id, nama_alat )
        )
      ''')
      .eq('status', 'pending')
      .order('id');

  return res;
}
Future<void> rejectPeminjaman(int id) async {
  final supabase = Supabase.instance.client;

  await supabase
      .from('peminjaman')
      .update({'status': 'rejected'})
      .eq('id', id);

  await simpanLog(
  aktivitas: 'Menolak peminjaman',
  peminjamanId: id,
);

}

  Future<List<dynamic>> _fetchData() async {
    return await supabase
        .from('peminjaman')
        .select('''
          id,
          nama,
          tanggal_pinjam,
          tanggal_kembali_rencana,
          status
        ''')
        .eq('status', 'pending')
        .order('tanggal_pinjam');
  }

  Future<void> _approve(int peminjamanId) async {
  // ambil detail alat
  final details = await supabase
      .from('detail_peminjaman')
      .select()
      .eq('peminjaman_id', peminjamanId);

  // kurangi stok
  for (final d in details) {
    await supabase.rpc('kurangi_stok', params: {
      'alat_id_input': d['alat_id'],
      'jumlah_input': d['jumlah'],
    });
  }

  // update status
  await supabase
      .from('peminjaman')
      .update({'status': 'disetujui'})
      .eq('id', peminjamanId);

  if (!mounted) return;
  await simpanLog(
  aktivitas: 'Menyetujui peminjaman',
  peminjamanId: peminjamanId,
);


  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Peminjaman disetujui')),
  );

  setState(() {});
}


  Future<void> _reject(int id) async {
    await supabase
        .from('peminjaman')
        .update({'status': 'ditolak'})
        .eq('id', id);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peminjaman Masuk')),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Center(child: Text('Tidak ada peminjaman'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final p = data[i];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(p['nama']),
                  subtitle: Text(
                    'Pinjam: ${p['tanggal_pinjam'].substring(0, 10)}\n'
                    'Kembali: ${p['tanggal_kembali_rencana'].substring(0, 10)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
  icon: const Icon(Icons.check),
  label: const Text('Approve'),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Setujui peminjaman ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _approve(p['id']);
            },
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  },
),


ElevatedButton.icon(
  icon: const Icon(Icons.close),
  label: const Text('Reject'),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  onPressed: () => rejectPeminjaman(p['id']),
),

                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
