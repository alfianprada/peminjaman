import 'package:flutter/material.dart';
import 'package:peminjaman_alat/auth/login_page.dart';
import 'package:peminjaman_alat/peminjam/daftar_alat.dart';
import 'package:peminjaman_alat/peminjam/peminjaman_saya.dart';
import 'package:peminjaman_alat/peminjam/profile_peminjam.dart';
import 'package:peminjaman_alat/peminjam/log_aktivitas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class DashboardPeminjam extends StatefulWidget {
  const DashboardPeminjam({super.key});

  @override
  State<DashboardPeminjam> createState() => _DashboardPeminjamState();
}

class _DashboardPeminjamState extends State<DashboardPeminjam> {
  final supabase = Supabase.instance.client;

  String namaPeminjam = '';
  List kategoriList = [];
  List alatList = [];
  String searchText = '';

  int? kategoriAktif;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNama();
    fetchKategori();
    fetchAlat();
  }

  // ================= LOAD USER =================
  Future<void> _loadNama() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('users')
        .select('nama')
        .eq('id', user.id)
        .single();

    setState(() => namaPeminjam = data['nama'] ?? 'Peminjam');
  }

  // ================= FETCH =================
  Future<void> fetchKategori() async {
    kategoriList = await supabase
        .from('kategori')
        .select()
        .order('nama_kategori');
    setState(() {});
  }

  Future<void> fetchAlat() async {
    setState(() => isLoading = true);

    alatList = kategoriAktif == null
        ? await supabase
            .from('alat')
            .select('id, nama_alat, stok, kondisi, kategori_id')
            .order('nama_alat')
        : await supabase
            .from('alat')
            .select('id, nama_alat, stok, kondisi, kategori_id')
            .eq('kategori_id', kategoriAktif!)
            .order('nama_alat');

    setState(() => isLoading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hallo, $namaPeminjam 👋'),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
          ),
        ),
      ),

      // ================= DRAWER =================
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(

              accountName: const Text('Peminjam'),
              accountEmail: Text(user?.email ?? '-'),
              currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
            ),
            _menuTile(Icons.dashboard, 'Dashboard', () {}),

            _menuTile(
              Icons.person,
              'Profile', () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfilePeminjamPage()));
            }),
            _menuTile(Icons.build, 'Daftar alat', () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PeminjamanPage()));
            }),
            _menuTile(Icons.assignment,'Peminjaman Saya',() {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PeminjamanSayaPage()));
  }),
            _menuTile(Icons.history, 'Log Aktivitas', () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LogAktivitasPagePeminjam()));
            }),
            const Divider(),
            _menuTile(Icons.logout, 'Logout', () async {
              await supabase.auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            }, color: Colors.red),
          ],
        ),
      ),

      // ================= BODY =================
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _searchBox(),
                  const SizedBox(height: 16),
            const Text('Kategori Alat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ===== KATEGORI =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  kategoriChip('Semua', null),
                  ...kategoriList.map(
                    (k) => kategoriChip(k['nama_kategori'], k['id']),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Daftar Alat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: alatList.length,
                      itemBuilder: (_, i) => alatCard(alatList[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= WIDGET =================
  Widget kategoriChip(String label, int? id) {
    final aktif = kategoriAktif == id;
    return GestureDetector(
      onTap: () {
        setState(() => kategoriAktif = id);
        fetchAlat();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: aktif ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(color: aktif ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget alatCard(Map alat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.build, color: Colors.blue, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alat['nama_alat'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Kondisi: ${alat['kondisi']}'),
              ],
            ),
          ),
          Column(
            children: [
              const Text('Stok'),
              Text(alat['stok'].toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap,
      {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }
  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchText = value.toLowerCase()),
        decoration: const InputDecoration(
          icon: Icon(Icons.search),
          hintText: 'Cari alat...',
          border: InputBorder.none,
        ),
      ),
    );
  }
}
