import 'package:flutter/material.dart';
import 'package:peminjaman_alat/admin/CRUD_alat.dart';
import 'package:peminjaman_alat/admin/CRUD_user.dart';
import 'package:peminjaman_alat/admin/crud_kategori.dart';
import 'package:peminjaman_alat/admin/crud_peminjaman.dart';
import 'package:peminjaman_alat/admin/crud_pengembalian.dart';
import 'package:peminjaman_alat/admin/dashboard_admin.dart';
import 'package:peminjaman_alat/admin/log_aktivitas.dart';
import 'package:peminjaman_alat/admin/profile_admin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/login_page.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    void go(Widget page) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Admin Bengkel'),
            accountEmail: Text(user?.email ?? '-'),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
          ),

          // ===== DASHBOARD =====
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => go(const DashboardAdmin()),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => go(const ProfileAdminPage()),
          ),

          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manajemen User'),
            onTap: () => go(
              CrudUserPage(
                onAddPetugas: () {},
                onAddPeminjam: () {},
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Manajemen Alat'),
            onTap: () => go(const CrudAlatPage()),
          ),

          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Kategori'),
            onTap: () => go(const CrudKategoriPage()),
          ),

          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Peminjaman'),
            onTap: () => go(const CrudPeminjamanPage()),
          ),

          ListTile(
            leading: const Icon(Icons.assignment_return),
            title: const Text('Pengembalian'),
            onTap: () => go(const CrudPengembalianPage()),
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Log Aktivitas'),
            onTap: () => go(const LogAktivitasPage()),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
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
    );
  }
}
