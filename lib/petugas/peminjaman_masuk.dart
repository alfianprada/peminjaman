import 'package:flutter/material.dart';
import 'package:peminjaman_alat/auth/login_page.dart';
import 'package:peminjaman_alat/petugas/dashboard_petugas.dart';
import 'package:peminjaman_alat/petugas/profile_petugas.dart';
import 'package:peminjaman_alat/petugas/log_aktivitas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:peminjaman_alat/utils/log_helper.dart';

class PeminjamanMasukPage extends StatefulWidget {
  const PeminjamanMasukPage({super.key});

  @override
  State<PeminjamanMasukPage> createState() => _PeminjamanMasukPageState();
}

class _PeminjamanMasukPageState extends State<PeminjamanMasukPage> {
  final supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser;

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
  // Ambil detail peminjaman
  final details = await supabase
      .from('detail_peminjaman')
      .select()
      .eq('peminjaman_id', peminjamanId);

  // Kurangi stok tiap alat
  for (final d in details) {
    await supabase.rpc('kurangi_stok', params: {
      'alat_id_input': d['alat_id'],
      'jumlah_input': d['jumlah'],
    });
  }

  // Update status
  await supabase
      .from('peminjaman')
      .update({'status': 'disetujui'})
      .eq('id', peminjamanId);

  // Log aktivitas petugas
  await simpanLog(
    aktivitas: 'Menyetujui peminjaman',
    peminjamanId: peminjamanId,
    role: 'petugas',
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Peminjaman disetujui')),
  );

  setState(() {});
}

  Future<void> _reject(int peminjamanId) async {
  // 1️⃣ Update status peminjaman
  await supabase
      .from('peminjaman')
      .update({'status': 'ditolak'})
      .eq('id', peminjamanId);

  // 2️⃣ Simpan log aktivitas petugas
  await simpanLog(
    aktivitas: 'Menolak pengajuan peminjaman',
    peminjamanId: peminjamanId,
    role: 'petugas',
  );

  if (!mounted) return;

  // 3️⃣ Feedback ke user
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Peminjaman ditolak')),
  );

  // 4️⃣ Refresh list
  setState(() {});
}

Future<List<dynamic>> _fetchDetailBarang(int peminjamanId) async {
  return await supabase
      .from('detail_peminjaman')
      .select('''
        jumlah,
        alat:alat!detail_peminjaman_alat_id_fkey (
          nama_alat
        )
      ''')
      .eq('peminjaman_id', peminjamanId);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================= APP BAR SAMA =================
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
                    'Peminjaman Masuk',
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
          ],
        ),
      ),
    ),
  ),


),

      // ================= DRAWER SAMA =================
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
                MaterialPageRoute(
                  builder: (_) => const DashboardPetugas(),
                ),
              ),
            ),

            _menuTile(
              icon: Icons.person,
              title: 'Profile',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilePetugasPage(),
                ),
              ),
            ),

            _menuTile(
              icon: Icons.assignment,
              title: 'Peminjaman Masuk',
              onTap: () => Navigator.pop(context), // halaman aktif
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
          padding: const EdgeInsets.all(12),
          itemCount: data.length,
          itemBuilder: (context, i) {
            final p = data[i];

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // ===== NAMA + STATUS =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p['nama'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Chip(
                  label: Text(
                    'PENDING',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ===== TANGGAL =====
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Pinjam: ${p['tanggal_pinjam'].substring(0, 10)}',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event_available, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Kembali: ${p['tanggal_kembali_rencana'].substring(0, 10)}',
                ),
              ],
            ),

            const Divider(height: 10),
            const SizedBox(height: 10),

            // ===== BARANG DIPINJAM =====
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text(
                'Barang yang Dipinjam',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              children: [
                FutureBuilder<List<dynamic>>(
                  future: _fetchDetailBarang(p['id']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Tidak ada barang'),
                      );
                    }

                    final items = snapshot.data!;

                    return Column(
                      children: items.map((item) {
                        return ListTile(
                          leading: const Icon(Icons.build_circle_outlined),
                          title: Text(item['alat']['nama_alat']),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'x${item['jumlah']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),

            const Divider(height: 20),

            // ===== BUTTON ACTION =====
            Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 20,color: Colors.black),
                label: const Text(
                  'Approve',
                  style: TextStyle(fontSize: 14,color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(110, 42), // ⬅ PERBESAR TOMBOL
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _approve(p['id']),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 20,color: Color.fromARGB(255, 255, 255, 255)),
                label: const Text(
                  'Reject',
                  style: TextStyle(fontSize: 14,color: Color.fromARGB(255, 255, 255, 255)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(110, 42), // ⬅ PERBESAR TOMBOL
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _reject(p['id']),
              ),
            ],
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
