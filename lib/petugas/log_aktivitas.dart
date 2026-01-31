import 'package:flutter/material.dart';
import 'package:peminjaman_alat/auth/login_page.dart';
import 'package:peminjaman_alat/petugas/dashboard_petugas.dart';
import 'package:peminjaman_alat/petugas/profile_petugas.dart';
import 'package:peminjaman_alat/petugas/peminjaman_masuk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogAktivitasPage extends StatelessWidget {
  final String role;
  const LogAktivitasPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      // ================= APP BAR =================
      appBar: AppBar(
        title: const Text('Log Aktivitas'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
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
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const PeminjamanMasukPage(),
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

      // ================= BODY =================
      body: FutureBuilder<List>(
 future: supabase
    .from('log_aktivitas')
    .select('''
      id,
      aktivitas,
      role,
      created_at,
      peminjaman:peminjaman_id (
        id,
        nama
      )
    ''')
    .order('created_at', ascending: false),

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

if (!snapshot.hasData || snapshot.data!.isEmpty) {
  return const Center(child: Text('Belum ada aktivitas'));
}


    final data = snapshot.data!;
    if (data.isEmpty) {
      return const Center(child: Text('Belum ada aktivitas'));
    }

    return ListView.builder(
  itemCount: data.length,
  itemBuilder: (context, i) {
    final log = data[i];
    final peminjaman = log['peminjaman'];
    final namaPeminjam = peminjaman?['nama'] ?? '-';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(
          log['role'] == 'petugas'
              ? Icons.person_2
              : Icons.person,
          color: log['role'] == 'petugas'
              ? Colors.green
              : Colors.blue,
        ),
        title: Text(log['aktivitas']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peminjam: $namaPeminjam'),
            Text('Role: ${log['role']}'),
            Text(
              'Waktu: ${log['created_at'].toString().substring(0, 19)}',
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
