import 'package:flutter/material.dart';
import 'package:peminjaman_alat/auth/login_page.dart';
import 'package:peminjaman_alat/peminjam/ajukan_peminjaman.dart';
import 'package:peminjaman_alat/peminjam/dashboard_peminjam.dart';
import 'package:peminjaman_alat/peminjam/log_aktivitas.dart';
import 'package:peminjaman_alat/peminjam/peminjaman_saya.dart';
import 'package:peminjaman_alat/peminjam/profile_peminjam.dart';
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
      appBar: AppBar(
        title: const Text('Daftar Alat'),
        actions: [
    Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
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
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    )
  ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
          ),
        ),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Peminjam'),
              accountEmail: Text(user?.email ?? '-'),
            ),

            _menuTile(
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardPeminjam(),
                ),
              ),
            ),

            _menuTile(
              icon: Icons.person,
              title: 'Profile',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilePeminjamPage(),
                ),
              ),
            ),

            _menuTile(
              icon: Icons.build,
              title: 'Daftar Alat',
              onTap: () => Navigator.pop(context),
            ),
            _menuTile(
              icon: Icons.assignment,
              title: 'Peminjaman Saya',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const PeminjamanSayaPage(),
                ),
              ),
            ),

            _menuTile(
              icon: Icons.history,
              title: 'Log Aktivitas',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LogAktivitasPagePeminjam(),
                ),
              ),
            ),

            const Divider(),

            _menuTile(
              icon: Icons.logout,
              title: 'Logout',
              color: Colors.red,
              onTap: () async {
                await supabase.auth.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
            ),
          ],
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
  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }
}
