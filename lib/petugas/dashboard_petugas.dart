import 'package:flutter/material.dart';
import 'package:peminjaman_alat/auth/login_page.dart';
import 'package:peminjaman_alat/petugas/log_aktivitas.dart';
import 'package:peminjaman_alat/petugas/peminjaman_masuk.dart';
import 'package:peminjaman_alat/petugas/profile_petugas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPetugas extends StatefulWidget {
  const DashboardPetugas({super.key});

  @override
  State<DashboardPetugas> createState() => _DashboardPetugasState();
}

class _DashboardPetugasState extends State<DashboardPetugas> {
  final supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser;

  List kategoriList = [];
  List alatList = [];

  int? kategoriAktif;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKategori();
    fetchAlat();
  }

  // ================= FETCH DATA =================

  Future<void> fetchKategori() async {
    final res = await supabase
        .from('kategori')
        .select()
        .order('nama_kategori');

    setState(() => kategoriList = res);
  }

  Future<void> fetchAlat() async {
    setState(() => isLoading = true);

    final res = kategoriAktif == null
        ? await supabase
            .from('alat')
            .select('id, nama_alat, stok, kondisi, kategori_id')
            .order('nama_alat')
        : await supabase
            .from('alat')
            .select('id, nama_alat, stok, kondisi, kategori_id')
            .eq('kategori_id', kategoriAktif!)
            .order('nama_alat');

    setState(() {
      alatList = res;
      isLoading = false;
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Petugas'),
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
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Petugas'),
              accountEmail: Text(user?.email ?? '-'),
            ),

            _menuTile(
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPetugas()),
              ),
            ),

            _menuTile(
              icon: Icons.person,
              title: 'Profile',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePetugasPage()),
              ),
            ),

            _menuTile(
              icon: Icons.assignment,
              title: 'Peminjaman Masuk',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PeminjamanMasukPage()),
              ),
            ),

            _menuTile(
              icon: Icons.history,
              title: 'Log Aktivitas',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LogAktivitasPage(role: 'petugas'),
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

      // ================= BODY =================
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Alat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ===== KATEGORI SCROLL =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
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

            const Text(
              'Daftar Alat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : alatList.isEmpty
                      ? const Center(child: Text('Tidak ada alat'))
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
    final isActive = kategoriAktif == id;

    return GestureDetector(
      onTap: () {
        setState(() => kategoriAktif = id);
        fetchAlat();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
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
          const Icon(Icons.build, color: Colors.blue, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alat['nama_alat'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Kondisi: ${alat['kondisi']}'),
              ],
            ),
          ),
          Column(
            children: [
              const Text('Stok'),
              Text(
                alat['stok'].toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
