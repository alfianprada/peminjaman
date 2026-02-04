import 'package:flutter/material.dart';
import 'package:peminjaman_alat/peminjam/log_aktivitas.dart';
import 'package:peminjaman_alat/utils/format_rupiah.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PeminjamanSayaPage extends StatefulWidget {
  const PeminjamanSayaPage({super.key});

  @override
  State<PeminjamanSayaPage> createState() => _PeminjamanSayaPageState();
}

class _PeminjamanSayaPageState extends State<PeminjamanSayaPage> {
  final supabase = Supabase.instance.client;

 Future<List<dynamic>> fetchPeminjaman() async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final res = await supabase
      .from('peminjaman')
      .select('''
        id,
        nama,
        tanggal_pinjam,
        tanggal_kembali_rencana,
        status,
        pengembalian (
          id
        ),
        detail_peminjaman!detail_peminjaman_peminjaman_id_fkey (
          jumlah,
          alat!detail_peminjaman_alat_id_fkey (
  nama_alat,
  harga,
  denda_per_hari
)

        )
      ''')
      .eq('user_id', user.id)
      .neq('status', 'selesai') // 🔥 INI KUNCINYA
      .neq('status', 'ditolak')
      .order('tanggal_pinjam', ascending: false);

  return res as List<dynamic>;
}

Future<Map<String, dynamic>> fetchAturanDenda() async {
  final res = await supabase
      .from('aturan_denda')
      .select()
      .single();

  return res;
}
int hitungDenda({
  required DateTime tanggalRencana,
  required DateTime tanggalKembali,
  required int hargaAlat,
  required int dendaPerHariAlat,
  required int jumlah,
  required String kondisi,
  required Map<String, dynamic> aturan,
}) {
  int denda = 0;

  int telatHari =
      tanggalKembali.difference(tanggalRencana).inDays;

  if (telatHari > 0) {
    denda +=telatHari * dendaPerHariAlat * jumlah;
  }

  final int totalHarga = hargaAlat * jumlah;

  if (kondisi == 'rusak') {
    final int persenRusak =
        (aturan['persen_rusak'] as num).toInt();
    denda += (persenRusak * totalHarga ~/ 100);
  }

  if (kondisi == 'hilang') {
    final int persenHilang =
        (aturan['persen_hilang'] as num).toInt();
    denda += (persenHilang * totalHarga ~/ 100);
  }

  return denda;
}




  Future<void> prosesPengembalian({
  required int peminjamanId,
  required int denda,
  required int telatHari,
}) async {
  final today = DateTime.now().toIso8601String().substring(0, 10);

  await supabase.from('pengembalian').insert({
    'peminjaman_id': peminjamanId,
    'tanggal_kembali': today,
    'kondisi_barang': 'baik',
    'terlambat_hari': telatHari,
    'denda': denda,
  });

  await supabase
      .from('peminjaman')
      .update({'status': 'selesai'})
      .eq('id', peminjamanId);

  await supabase.from('log_aktivitas').insert({
    'user_id': supabase.auth.currentUser!.id,
    'role': 'peminjam',
    'aktivitas': 'Melakukan pengembalian alat',
    'peminjaman_id': peminjamanId,
  });

  setState(() {});
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
  preferredSize: const Size.fromHeight(90),
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
          top: 4, // 🔽 supaya tidak mepet atas
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
              ),
            ),

            const SizedBox(width: 10),

            // 📦 JUDUL HALAMAN
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peminjaman Saya',
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
                      'Peminjam',
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


            // 🛒 KERANJANG (FUNGSI ASLI – TIDAK DIUBAH)
            Stack(
              children: [
                IconButton(
      icon: const Icon(Icons.history,color: Colors.white,),
      tooltip: 'Riwayat Aktivitas',
       onPressed: () {
         Navigator.push(
           context,
           MaterialPageRoute(
             builder: (_) => const LogAktivitasPagePeminjam(),
           ),
         );
       },
     ),
    
              ],
            ),
          ],
        ),
      ),
    ),
  ),
),
      body: FutureBuilder<Map<String, dynamic>>(
  future: fetchAturanDenda(),
  builder: (context, aturanSnap) {
    if (!aturanSnap.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final aturan = aturanSnap.data!;

    return FutureBuilder<List<dynamic>>(
      future: fetchPeminjaman(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return const Center(child: Text('Tidak ada peminjaman'));
        }

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final p = data[index];
            final List details = p['detail_peminjaman'] ?? [];

            final sudahDikembalikan = p['pengembalian'] != null;
            final bolehKembali =
                p['status'] == 'disetujui' && !sudahDikembalikan;

            // 🔥 HITUNG DENDA TOTAL
            int totalDenda = 0;
            int telatHari = 0;

            final tglRencana =
                DateTime.parse(p['tanggal_kembali_rencana']);
            final tglSekarang = DateTime.now();

            telatHari =
                tglSekarang.difference(tglRencana).inDays;
            if (telatHari < 0) telatHari = 0;

            for (final d in details) {
              final alat = d['alat'];
              if (alat == null) continue;

              totalDenda += hitungDenda(
  tanggalRencana: tglRencana,
  tanggalKembali: tglSekarang,
  hargaAlat: alat['harga'] ?? 0,
  dendaPerHariAlat: alat['denda_per_hari'] ?? 0,
  jumlah: d['jumlah'],
  kondisi: 'baik',
  aturan: aturan,
);


            }

            return Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peminjaman ${p['nama']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text('Pinjam: ${p['tanggal_pinjam']}'),
                    Text('Kembali: ${p['tanggal_kembali_rencana']}'),
                    Text('Status: ${p['status']}'),

                    if (telatHari > 0)
                      Text(
                        'Terlambat: $telatHari hari',
                        style: const TextStyle(color: Colors.red),
                      ),

                    const Divider(),

                    const Text(
                      'Detail Alat:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    ...details.map((d) {
                      final alat = d['alat'];
                      if (alat == null) return const SizedBox();

                      return Row(
                        children: [
                          const Icon(Icons.build, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(alat['nama_alat']),
                          ),
                          Text('x${d['jumlah']}'),
                        ],
                      );
                    }).toList(),

                    const SizedBox(height: 8),

                    Text(
  'Denda: ${formatRupiah(totalDenda)}',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.red,
  ),
),


                    const SizedBox(height: 12),

                    if (bolehKembali)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.assignment_return),
                          label: const Text('KEMBALIKAN ALAT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Konfirmasi'),
                                content: Text(
  'Denda: ${formatRupiah(totalDenda)}\nYakin ingin mengembalikan?',
),

                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Ya'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await prosesPengembalian(
                                peminjamanId: p['id'],
                                denda: totalDenda,
                                telatHari: telatHari,
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  },
),

    );}
}
