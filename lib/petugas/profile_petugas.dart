import 'package:flutter/material.dart';
import 'package:peminjaman_alat/petugas/dashboard_petugas.dart';
import 'package:peminjaman_alat/petugas/log_aktivitas.dart';
import 'package:peminjaman_alat/petugas/peminjaman_masuk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_page.dart';

class ProfilePetugasPage extends StatelessWidget {
  const ProfilePetugasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),

      // ================= DRAWER (SAMA DENGAN DASHBOARD) =================
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
              onTap: () => Navigator.pop(context), // sudah di profile
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
      body: SafeArea(
        child: FutureBuilder(
          future: supabase
              .from('users')
              .select()
              .eq('id', user!.id)
              .single(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data as Map<String, dynamic>;

            return Column(
              children: [
                // ================= HEADER =================
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon:
                              const Icon(Icons.menu, color: Colors.white),
                          onPressed: () =>
                              Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Profile Petugas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ================= AVATAR =================
                const CircleAvatar(
                  radius: 55,
                  backgroundColor: Color(0xFF1976D2),
                  child: Icon(Icons.badge,
                      size: 50, color: Colors.white),
                ),

                const SizedBox(height: 32),

                // ================= INFO =================
                _infoItem('Nama', data['nama'] ?? '-'),
                _infoItem('Role', data['role'] ?? 'petugas'),
                _infoItem('Email', data['email'] ?? user.email ?? '-'),

                const SizedBox(height: 40),

            // ===== LOGOUT BUTTON =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF039BE5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                    );
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ================= WIDGET =================
  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label :',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const Divider(thickness: 1),
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
