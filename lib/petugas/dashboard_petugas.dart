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
  String namaPeminjam = '';

  List kategoriList = [];
  List alatList = [];
  String searchText = '';

  int? kategoriAktif;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKategori();
    fetchAlat();
    _loadNamaPeminjam();
  }

  Future<int> countPendingPeminjaman() async {
  final data = await Supabase.instance.client
      .from('peminjaman')
      .select('id')
      .eq('status', 'pending');

  return data.length;
}

int getTotalAlat() {
  return alatList.length;
}

int getTotalStok() {
  int total = 0;
  for (var a in alatList) {
    total += (a['stok'] as int);
  }
  return total;
}

  Future<void> _loadNamaPeminjam() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final data = await supabase
      .from('users')
      .select('nama')
      .eq('id', user.id)
      .single();

  setState(() {
    namaPeminjam = data['nama'] ?? 'Petugas';
  });
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
            // ☰ MENU
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
                    namaPeminjam,
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
                      'Petugas',
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

            // 🔔 NOTIFIKASI
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications, color: Colors.white),
            ),
          ],
        ),
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
              currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
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

              menuWithBadge(
              icon: Icons.assignment,
              title: 'Peminjaman Masuk',
              badgeFuture: countPendingPeminjaman(),
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
            _searchBox(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
              Row(
                children: [
                  _summaryCard(
                    icon: Icons.inventory_2,
                    title: 'Total Alat',
                    value: getTotalAlat().toString(),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _summaryCard(
                    icon: Icons.storage,
                    title: 'Total Stok',
                    value: getTotalStok().toString(),
                    color: Colors.green,
                  ),
                ],
              ),
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
  return Card(
    elevation: 3,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.build_circle,
              color: Colors.blue,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alat['nama_alat'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alat['kondisi'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              const Text(
                'Stok',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
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
    ),
  );
}

  Widget menuWithBadge({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  required Future<int> badgeFuture,
  Color color = Colors.black,
}) {
  return FutureBuilder<int>(
    future: badgeFuture,
    builder: (context, snapshot) {
      final count = snapshot.data ?? 0;

      return ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: count > 0
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      );
    },
  );
}
Widget _summaryCard({
  required IconData icon,
  required String title,
  required String value,
  required Color color,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.85),
            color.withOpacity(0.65),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
