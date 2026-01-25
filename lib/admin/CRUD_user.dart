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
        .inFilter('role', ['petugas', 'peminjam'])
        .order('created_at');
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
                DropdownMenuItem(value: 'petugas', child: Text('Petugas')),
                DropdownMenuItem(value: 'peminjam', child: Text('Peminjam')),
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

  // ===== HAPUS USER =====
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

  Color _roleColor(String role) =>
      role == 'petugas' ? Colors.orange : Colors.green;

  IconData _roleIcon(String role) =>
      role == 'petugas' ? Icons.badge : Icons.person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen User')),
      body: FutureBuilder<List<dynamic>>(
        future: _getUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(child: Text('Belum ada user'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _roleColor(user['role']).withOpacity(0.15),
                    child: Icon(
                      _roleIcon(user['role']),
                      color: _roleColor(user['role']),
                    ),
                  ),
                  title: Text(
                    user['nama'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email']),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          user['role'].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _roleColor(user['role']),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') {
                        _editUser(context, user);
                      } else {
                        _deleteUser(context, user['id']);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      // ===== FAB =====
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'peminjam',
            backgroundColor: Colors.green,
            onPressed: () async {
              widget.onAddPeminjam();
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() {});
            },
            label: const Text('Tambah Peminjam'),
            icon: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'petugas',
            backgroundColor: Colors.orange,
            onPressed: () async {
              widget.onAddPetugas();
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() {});
            },
            label: const Text('Tambah Petugas'),
            icon: const Icon(Icons.badge),
          ),
        ],
      ),
    );
  }
}
