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

Future<int> countPendingPeminjaman() async {
  final supabase = Supabase.instance.client;

  final data = await supabase
      .from('peminjaman')
      .select('id')
      .eq('status', 'pending');

  return data.length;
}

    return Scaffold(
      // ================= APP BAR =================
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
                    'Log Aktivitas',
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

            menuWithBadgeStateless(
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
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  itemCount: data.length,
  itemBuilder: (context, i) {
    final log = data[i];
    final peminjaman = log['peminjaman'];
    final namaPeminjam = peminjaman?['nama'] ?? '-';

    final isPetugas = log['role'] == 'petugas';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== ICON =====
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPetugas
                    ? Colors.green.withOpacity(0.15)
                    : Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPetugas
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
                color: isPetugas ? Colors.green : Colors.blue,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // ===== CONTENT =====
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AKTIVITAS
                  Text(
                    log['aktivitas'],
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // PEMINJAM
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        namaPeminjam,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ROLE + WAKTU
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isPetugas
                              ? Colors.green.withOpacity(0.15)
                              : Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          log['role'].toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                isPetugas ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        log['created_at']
                            .toString()
                            .substring(0, 16),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
Widget menuWithBadgeStateless({
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
