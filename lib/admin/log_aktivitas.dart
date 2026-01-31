import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogAktivitasPage extends StatefulWidget {
  const LogAktivitasPage({super.key});

  @override
  State<LogAktivitasPage> createState() => _LogAktivitasPageState();
}

class _LogAktivitasPageState extends State<LogAktivitasPage> {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> _getLog() async {
    return await supabase
        .from('log_aktivitas')
        .select('''
          id,
          aktivitas,
          role,
          created_at,
          peminjaman_id,
          peminjaman(
            nama
          )
        ''')
        .order('created_at', ascending: false);
  }

  // ===== HAPUS LOG =====
  void _hapusLog(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Log'),
        content: const Text('Yakin ingin menghapus log aktivitas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await supabase.from('log_aktivitas').delete().eq('id', id);
              Navigator.pop(context);
              setState(() {}); // refresh list
            },
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Aktivitas Admin'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _getLog(),
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
              final peminjamNama =
                  peminjaman != null ? peminjaman['nama'] : '-';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading:
                      const Icon(Icons.event_note, color: Colors.blue),
                  title: Text(log['aktivitas'] ?? '-'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${log['role'] ?? '-'}'),
                      Text('Peminjam: $peminjamNama'),
                      Text(
                        'Tanggal: ${log['created_at'].toString().substring(0, 19)}',
                      ),
                    ],
                  ),

                  // ===== TOMBOL HAPUS =====
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _hapusLog(log['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
