import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrudUserPage extends StatefulWidget {
  final VoidCallback onAddPetugas;
  final VoidCallback onAddPeminjam;

  const CrudUserPage({
    super.key,
    required this.onAddPetugas,
    required this.onAddPeminjam,
  });

  @override
  State<CrudUserPage> createState() => _CrudUserPageState();
}

class _CrudUserPageState extends State<CrudUserPage> {
  final supabase = Supabase.instance.client;

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
    backgroundColor: const Color(0xFFE0E0E0),
    body: SafeArea(
      child: Column(
        children: [
          // ===== HEADER (SAMA PROFILE ADMIN) =====
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
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Manajemen User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

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
          onTap: widget.onAddPetugas,
        ),
        const SizedBox(height: 8),
        _fab(
          color: Colors.green,
          icon: Icons.person,
          label: 'Tambah Peminjam',
          onTap: widget.onAddPeminjam,
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
      onPressed: () async {
        onTap();
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {});
      },
    );
  }
}
