import 'package:flutter/material.dart';
import 'package:peminjaman_alat/peminjam/ajukan_peminjaman.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:peminjaman_alat/models/keranjang_items.dart';

class PeminjamanPage extends StatefulWidget {
  const PeminjamanPage({super.key});

  @override
  State<PeminjamanPage> createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  final supabase = Supabase.instance.client;
  List<KeranjangItem> keranjang = [];
  User? user;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    user = supabase.auth.currentUser;
    debugPrint('👤 USER LOGIN: ${user?.email}');
  }

  @override
  void dispose() {
    debugPrint('❌ PeminjamanPage DISPOSE');
    super.dispose();
  }

  // ================= FETCH ALAT =================
  Future<List> _getAlat() async {
    debugPrint('🔄 FETCH DATA ALAT...');
    try {
      final res = await supabase
          .from('alat')
          .select('id, nama_alat, stok, foto_alat');

      debugPrint('📦 DATA ALAT (${res.length} item): $res');
      return res;
    } catch (e) {
      debugPrint('❌ ERROR FETCH ALAT: $e');
      return [];
    }
  }

  // ================= TAMBAH KERANJANG =================
  void tambah(int id, String nama) {
    debugPrint('➕ TAMBAH ALAT → id=$id nama=$nama');

    final index = keranjang.indexWhere((e) => e.alatId == id);

    setState(() {
      if (index == -1) {
        keranjang.add(KeranjangItem(alatId: id, nama: nama));
        debugPrint('🆕 ALAT BARU DITAMBAH');
      } else {
        keranjang[index].jumlah++;
        debugPrint('🔁 JUMLAH DITAMBAH → ${keranjang[index].jumlah}');
      }
    });

    debugPrint(
      '🛒 ISI KERANJANG: ${keranjang.map((e) => '${e.nama}(${e.jumlah})').toList()}',
    );
  }

  // ================= KERANJANG =================
  void _showKeranjang() {
    debugPrint('🛒 BUKA KERANJANG');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        if (keranjang.isEmpty) {
          debugPrint('⚠️ KERANJANG KOSONG');
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Keranjang masih kosong')),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Keranjang Peminjaman',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),

              ...keranjang.map(
                (e) => ListTile(
                  title: Text(e.nama),
                  subtitle: Text('Jumlah: ${e.jumlah}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      debugPrint('🗑 HAPUS: ${e.nama}');
                      setState(() => keranjang.remove(e));
                      Navigator.pop(context);
                      _showKeranjang();
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('AJUKAN PEMINJAMAN'),
                  onPressed: () async {
                    debugPrint('➡️ KE HALAMAN AJUKAN PEMINJAMAN');

                    Navigator.pop(context);

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AjukanPeminjamanPage(items: keranjang),
                      ),
                    );

                    if (!mounted) {
                      debugPrint('⚠️ WIDGET SUDAH DISPOSE, BATAL setState');
                      return;
                    }

                    debugPrint('🧹 KERANJANG DIKOSONGKAN');
                    setState(() => keranjang.clear());
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 BUILD PeminjamanPage');

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
              padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 10),
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
                  const Expanded(
                    child: Text(
                      'Daftar Alat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart,
                            color: Colors.white),
                        onPressed: _showKeranjang,
                      ),
                      if (keranjang.isNotEmpty)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: Colors.red,
                            child: Text(
                              keranjang.length.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: FutureBuilder(
        future: _getAlat(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('⏳ LOADING DATA...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('❌ SNAPSHOT ERROR: ${snapshot.error}');
            return const Center(child: Text('Terjadi kesalahan'));
          }

          final data = snapshot.data as List;

          if (data.isEmpty) {
            debugPrint('⚠️ DATA ALAT KOSONG');
            return const Center(child: Text('Tidak ada alat'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: data.map((a) {
              debugPrint('🧰 RENDER ALAT: ${a['nama_alat']}');

              if (a['foto_alat'] != null && a['foto_alat'] != '') {
                debugPrint('🖼 FOTO URL: ${a['foto_alat']}');
              }

              return Card(
                child: ListTile(
                  leading: a['foto_alat'] != null && a['foto_alat'] != ''
                      ? Image.network(
                          a['foto_alat'],
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(a['nama_alat']),
                  subtitle: Text('Stok: ${a['stok']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: a['stok'] > 0
                        ? () => tambah(a['id'], a['nama_alat'])
                        : null,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
