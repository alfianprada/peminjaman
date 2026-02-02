import 'package:flutter/material.dart';
import 'package:peminjaman_alat/auth/login_page.dart';
import 'package:peminjaman_alat/peminjam/daftar_alat.dart';
import 'package:peminjaman_alat/peminjam/dashboard_peminjam.dart';
import 'package:peminjaman_alat/peminjam/peminjaman_saya.dart';
import 'package:peminjaman_alat/peminjam/profile_peminjam.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogAktivitasPagePeminjam extends StatelessWidget {
  const LogAktivitasPagePeminjam({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    final user = supabase.auth.currentUser;


    // ================= QUERY LOG PEMINJAM =================
    Future<List<dynamic>> fetchLogs() async {
      if (userId == null) return [];
      return await supabase.from('log_aktivitas').select('''
        id,
        aktivitas,
        role,
        created_at,
        peminjaman_id,
        peminjaman(
          nama
        )
      ''')
      .eq('user_id', userId) // hanya log peminjam ini
      .order('created_at', ascending: false);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Aktivitas Peminjam'),
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
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const PeminjamanPage(),
                ),
              ),
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
              onTap: () => Navigator.pop(context), // halaman aktif
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
      body: FutureBuilder<List<dynamic>>(
        future: fetchLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Belum ada aktivitas'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final log = data[i];
              final peminjaman = log['peminjaman'];
              final peminjamNama = peminjaman != null ? peminjaman['nama'] : '-';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.event_note, color: Colors.green),
                  title: Text(log['aktivitas'] ?? '-'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${log['role'] ?? '-'}'),
                      if (peminjaman != null) Text('Peminjam: $peminjamNama'),
                      Text('Tanggal: ${log['created_at'].toString().substring(0, 19)}'),
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
