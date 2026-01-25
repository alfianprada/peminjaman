import 'package:flutter/material.dart';
import 'package:peminjaman_alat/admin/CRUD_alat.dart';
import 'package:peminjaman_alat/admin/CRUD_user.dart';
import 'package:peminjaman_alat/admin/crud_kategori.dart';
import 'package:peminjaman_alat/admin/crud_peminjaman.dart';
import 'package:peminjaman_alat/admin/crud_pengembalian.dart';
import 'package:peminjaman_alat/admin/log_aktivitas.dart';
import 'package:peminjaman_alat/admin/profile_admin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_page.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  void _showAddUserDialog(BuildContext context, String role) {
    final namaC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(role == 'petugas' ? 'Tambah Petugas' : 'Tambah Peminjam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaC, decoration: const InputDecoration(labelText: 'Nama')),
            TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email')),
            TextField(
              controller: passC,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            child: const Text('SIMPAN'),
            onPressed: () async {
              final supabase = Supabase.instance.client;
              final res = await supabase.auth.signUp(
                email: emailC.text,
                password: passC.text,
              );

              await supabase.from('users').insert({
                'id': res.user!.id,
                'nama': namaC.text,
                'email': emailC.text,
                'role': role,
              });

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

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

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileAdminPage()),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('User'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CrudUserPage(
                  onAddPetugas: () => _showAddUserDialog(context, 'petugas'),
                  onAddPeminjam: () => _showAddUserDialog(context, 'peminjam'),
                ),
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('CRUD Alat'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrudAlatPage()),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('CRUD Kategori'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrudKategoriPage()),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('CRUD Peminjaman'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrudPeminjamanPage()),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.assignment_return),
            title: const Text('CRUD Pengembalian'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrudPengembalianPage()),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Log Aktivitas'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogAktivitasPage()),
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hallo, Admin 👋'),
      ),
      drawer: _buildDrawer(context),
      body: ListView(
  padding: const EdgeInsets.all(16),
  children: [
    const Text(
      'Kategori Alat',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    _kategoriSection(),

    const SizedBox(height: 24),

    const Text(
      'Daftar Alat Bengkel',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    _alatSection(),
  ],
),

    );
  }
Widget _kategoriSection() {
  final supabase = Supabase.instance.client;

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Alat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          FutureBuilder(
            future: supabase
                .from('kategori')
                .select()
                .order('nama_kategori'),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData ||
                  (snapshot.data as List).isEmpty) {
                return const Text('Belum ada kategori');
              }

              final data = snapshot.data as List;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.map((k) {
                  return Chip(
                    label: Text(k['nama_kategori']),
                    backgroundColor: Colors.blue.shade50,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    ),
  );
}
Widget _alatSection() {
  final supabase = Supabase.instance.client;

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Alat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          FutureBuilder(
            future: supabase.from('alat').select(
              '''
              id,
              nama_alat,
              stok,
              harga,
              kategori:kategori_id (nama_kategori)
              ''',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData ||
                  (snapshot.data as List).isEmpty) {
                return const Text('Belum ada alat');
              }

              final data = snapshot.data as List;

              return Column(
                children: data.map((a) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      a['nama_alat'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Kategori: ${a['kategori']?['nama_kategori'] ?? '-'}\n'
                      'Stok: ${a['stok']}',
                    ),
                    trailing: const Icon(Icons.build, color: Colors.grey),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    ),
  );
}

}

