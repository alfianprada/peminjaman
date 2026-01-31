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
  // 1️⃣ Ambil detail peminjaman
  final details = await supabase
      .from('detail_peminjaman')
      .select()
      .eq('peminjaman_id', peminjamanId);

  // 2️⃣ Kurangi stok tiap alat
  for (final d in details) {
    await supabase.rpc('kurangi_stok', params: {
      'alat_id_input': d['alat_id'],
      'jumlah_input': d['jumlah'],
    });
  }

  // 3️⃣ Update status
  await supabase
      .from('peminjaman')
      .update({'status': 'disetujui'})
      .eq('id', peminjamanId);

  // 4️⃣ Log aktivitas petugas
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================= APP BAR SAMA =================
      appBar: AppBar(
        title: const Text('Peminjaman Masuk'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
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
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        onPressed: () => _approve(p['id']),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => _reject(p['id']),
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
