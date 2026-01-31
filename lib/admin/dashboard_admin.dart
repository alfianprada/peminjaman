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

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  final supabase = Supabase.instance.client;

  String searchText = '';
  int? selectedKategoriId;

  // ================= ADD USER =================
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

  // ================= DRAWER =================
  Drawer _buildDrawer(BuildContext context) {
    final user = supabase.auth.currentUser;

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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileAdminPage())),
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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrudAlatPage())),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('CRUD Kategori'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrudKategoriPage())),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('CRUD Peminjaman'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrudPeminjamanPage())),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_return),
            title: const Text('CRUD Pengembalian'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrudPengembalianPage())),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Log Aktivitas'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogAktivitasPage(rolw: 'admin',))),
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Hallo Admin, ${user?.email?.split('@').first ?? 'Admin'} 👋',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.notifications_none, color: Colors.white),
                ],
              ),
            ),

            // ===== CONTENT =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _searchBox(),
                  const SizedBox(height: 16),
                  const Text('Kategori Alat', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _kategoriSectionHorizontal(),
                  const SizedBox(height: 24),
                  const Text('Daftar Alat Bengkel', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _alatSectionCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SEARCH =================
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

  // ================= KATEGORI =================
  Widget _kategoriSectionHorizontal() {
    return SizedBox(
      height: 80,
      child: FutureBuilder(
        future: supabase.from('kategori').select().order('nama_kategori'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data as List;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final isSelected = selectedKategoriId == data[i]['id'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedKategoriId = isSelected ? null : data[i]['id'];
                  });
                },
                child: Container(
                  width: 90,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1976D2) : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      data[i]['nama_kategori'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ================= ALAT =================
  Widget _alatSectionCard() {
    return FutureBuilder(
      future: supabase.from('alat').select(
        '''
        id,
        nama_alat,
        stok,
        kategori_id,
        kategori:kategori_id (nama_kategori)
        ''',
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        List data = snapshot.data as List;

        if (searchText.isNotEmpty) {
          data = data.where((a) => a['nama_alat'].toLowerCase().contains(searchText)).toList();
        }

        if (selectedKategoriId != null) {
          data = data.where((a) => a['kategori_id'] == selectedKategoriId).toList();
        }

        if (data.isEmpty) return const Center(child: Text('Data tidak ditemukan'));

        return Column(
          children: data.map((a) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.build, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['nama_alat'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          'Kategori: ${a['kategori']?['nama_kategori'] ?? '-'}\nStok: ${a['stok']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
