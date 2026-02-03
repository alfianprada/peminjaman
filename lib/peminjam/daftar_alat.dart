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
  User?user;
  
@override
  void initState() {
    super.initState();
    user = supabase.auth.currentUser;
  }
  void tambah(int id, String nama) {
    final index = keranjang.indexWhere((e) => e.alatId == id);
    setState(() {
      if (index == -1) {
        keranjang.add(KeranjangItem(alatId: id, nama: nama));
      } else {
        keranjang[index].jumlah++;
      }
    });
  }
  void _showKeranjang() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      if (keranjang.isEmpty) {
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

            ...keranjang.map((e) => ListTile(
                  title: Text(e.nama),
                  subtitle: Text('Jumlah: ${e.jumlah}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => keranjang.remove(e));
                      Navigator.pop(context);
                      _showKeranjang();
                    },
                  ),
                )),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('AJUKAN PEMINJAMAN'),
                onPressed: () async {
                  Navigator.pop(context);

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AjukanPeminjamanPage(items: keranjang),
                    ),
                  );

                  // kosongkan keranjang setelah submit
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
            // 🧰 LOGO APLIKASI
            Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(width: 12),

            // 📦 JUDUL HALAMAN
            const Expanded(
              child: Text(
                'Daftar Alat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 🛒 KERANJANG (FUNGSI ASLI – TIDAK DIUBAH)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                  ),
                  onPressed: () => _showKeranjang(),
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
                          fontWeight: FontWeight.bold,
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
        future: supabase.from('alat').select('id, nama_alat, stok'),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data as List;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: data.map((a) {
              return Card(
                child: ListTile(
                  title: Text(a['nama_alat']),
                  subtitle: Text('Stok: ${a['stok']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () => tambah(a['id'], a['nama_alat']),
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
