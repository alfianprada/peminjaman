import 'package:flutter/material.dart';
import 'package:peminjaman_alat/peminjam/ajukan_peminjaman.dart';
import 'package:peminjaman_alat/peminjam/profile_peminjam.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_page.dart';
import 'package:peminjaman_alat/models/keranjang_items.dart';

class DashboardPeminjam extends StatefulWidget {
  const DashboardPeminjam({super.key});

  @override
  State<DashboardPeminjam> createState() => _DashboardPeminjamState();
}

class _DashboardPeminjamState extends State<DashboardPeminjam> {
  final supabase = Supabase.instance.client;
  List<KeranjangItem> keranjang = [];

  void kurangiDariKeranjang(int alatId) {
  final index = keranjang.indexWhere((e) => e.alatId == alatId);

  if (index != -1) {
    setState(() {
      if (keranjang[index].jumlah > 1) {
        keranjang[index].jumlah--;
      } else {
        keranjang.removeAt(index);
      }
    });
  }
}

void hapusDariKeranjang(int alatId) {
  setState(() {
    keranjang.removeWhere((e) => e.alatId == alatId);
  });
}


  void tambahKeKeranjang(int alatId, String nama) {
  debugPrint('ADD ALAT -> id: $alatId | nama: $nama');

  final index = keranjang.indexWhere((e) => e.alatId == alatId);

  setState(() {
    if (index == -1) {
      keranjang.add(KeranjangItem(alatId: alatId, nama: nama));
    } else {
      keranjang[index].jumlah++;
    }
  });
}




  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
  title: const Text('Hallo Petugas, Alfian'),
  actions: const [
    Padding(
      padding: EdgeInsets.only(right: 12),
      child: Icon(Icons.notifications),
    ),
  ],
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
),

      floatingActionButton: keranjang.isEmpty
    ? null
    : FloatingActionButton.extended(
        icon: const Icon(Icons.shopping_cart),
        label: Text('Ajukan (${keranjang.length})'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AjukanPeminjamanPage(items: keranjang),
            ),
          );
        },
      ),


      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person, size: 32),
              ),
              accountName: const Text('Peminjam'),
              accountEmail: Text(user?.email ?? '-'),
            ),

            _menuTile(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePeminjamPage()),
                );
              },
            ),

            _menuTile(
              icon: Icons.build,
              title: 'Daftar Alat',
              onTap: () => Navigator.pop(context),
            ),
            _menuTile(
              icon: Icons.assignment,
              title: 'Peminjaman Saya',
              onTap: () => Navigator.pop(context),
            ),

            const Spacer(),

            _menuTile(
              icon: Icons.logout,
              title: 'Logout',
              color: Colors.red,
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
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

      body: ListView(
        padding: const EdgeInsets.all(16),
  children: [
        const Text(
  'Daftar Alat',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
const SizedBox(height: 12),

FutureBuilder(
  future: supabase.from('alat').select('id, nama_alat, stok'),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = snapshot.data as List;

    return Column(
      children: data.map((a) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.build),
            title: Text(a['nama_alat']),
            subtitle: Text('Stok: ${a['stok']}'),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () {
  final int alatId = a['id'] as int;
  final String nama = a['nama_alat'] as String;

  tambahKeKeranjang(alatId, nama);
},


            ),
          ),
        );
      }).toList(),
    );
  },
),
const SizedBox(height: 24),
const Text(
  'Keranjang',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),

keranjang.isEmpty
    ? const Text('Keranjang masih kosong')
    : Column(
        children: keranjang.map((e) {
          return Card(
            child: ListTile(
              title: Text(e.nama),
              subtitle: Text('Jumlah: ${e.jumlah}'),
              leading: IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => kurangiDariKeranjang(e.alatId),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() => e.jumlah++);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => hapusDariKeranjang(e.alatId),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),



          const Text(
            'Menu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _menuCard(
            icon: Icons.add_circle,
            title: 'Ajukan Peminjaman',
            subtitle: 'Pinjam alat bengkel',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AjukanPeminjamanPage(
                  items: keranjang,
                ),
                ),
              );
            },
          ),
          _menuCard(
            icon: Icons.list_alt,
            title: 'Status Peminjaman',
            subtitle: 'Lihat status peminjaman',
            onTap: () {},
          ),
        ]
      ),
    );
  }


  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
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


