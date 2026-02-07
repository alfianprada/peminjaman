import 'package:flutter/material.dart';
import 'package:peminjaman_alat/admin/drawer_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrudUserPage extends StatefulWidget {
  const CrudUserPage({super.key});

  @override
  State<CrudUserPage> createState() => _CrudUserPageState();
}

class _CrudUserPageState extends State<CrudUserPage> {
  final supabase = Supabase.instance.client;

  void _showAddUserDialog(String role) {
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('BATAL'),
        ),
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
            setState(() {});
          },
        ),
      ],
    ),
  );
}

  Future<List<dynamic>> _getUsers() async {
    return await supabase
        .from('users')
        .select()
        .order('created_at');
  }

  // ===== ROLE STYLE =====
  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.blue;
      case 'petugas':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'petugas':
        return 'Petugas';
      default:
        return 'User';
    }
  }

  // ===== EDIT USER =====
  void _editUser(BuildContext context, Map user) {
    final namaC = TextEditingController(text: user['nama']);
    String role = user['role'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaC,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'petugas', child: Text('Petugas')),
                DropdownMenuItem(value: 'peminjam', child: Text('User')),
              ],
              onChanged: (v) => role = v!,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            child: const Text('SIMPAN'),
            onPressed: () async {
              await supabase.from('users').update({
                'nama': namaC.text,
                'role': role,
              }).eq('id', user['id']);

              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // ===== DELETE =====
  void _deleteUser(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus User'),
        content: const Text('Yakin ingin menghapus user ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('HAPUS'),
            onPressed: () async {
              await supabase.from('users').delete().eq('id', id);
              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // ===== UI =====
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
                    'Manajemen User',
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
                      'Admin',
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
    drawer: const AdminDrawer(),
    backgroundColor: const Color(0xFFE0E0E0),
    body: SafeArea(
      child: Column(
        children: [

          // ===== CONTENT =====
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _getUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i];
                    final color = _roleColor(user['role']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: color,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Name : ${user['nama']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text("Email : ${user['email']}"),
                                  const SizedBox(height: 6),
                                  Chip(
                                    label: Text(
                                      _roleLabel(user['role']),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: color,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (_) => user['role'] == 'admin'
                                  ? const [
                                      PopupMenuItem(
                                        enabled: false,
                                        child: Text('Admin tidak dapat diubah'),
                                      ),
                                    ]
                                  : const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                    ],
                              onSelected: (v) {
                                if (v == 'edit') _editUser(context, user);
                                if (v == 'delete') _deleteUser(context, user['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),

    // ===== FLOATING BUTTON =====
    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _fab(
          color: Colors.orange,
          icon: Icons.badge,
          label: 'Tambah Petugas',
          onTap: () => _showAddUserDialog('petugas'),
        ),
        const SizedBox(height: 8),
        _fab(
          color: Colors.green,
          icon: Icons.person,
          label: 'Tambah Peminjam',
          onTap: () => _showAddUserDialog('peminjam'),
        ),
      ],
     ),
    );
   }
  Widget _fab({
  required Color color,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return FloatingActionButton.extended(
    heroTag: label,
    backgroundColor: color,
    icon: Icon(icon),
    label: Text(label),
    onPressed: onTap,
  );
}
}
