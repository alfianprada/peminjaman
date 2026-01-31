import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogAktivitasPagePeminjam extends StatelessWidget {
  const LogAktivitasPagePeminjam({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    // ================= QUERY LOG PEMINJAM =================
    Future<List<dynamic>> fetchLogs() async {
      if (userId == null) return [];
      return await supabase.from('log_aktivitas').select('''
        id,
        aktivitas,
        role,
        created_at,
        peminjaman_id,
        peminjaman(
          nama
        )
      ''')
      .eq('user_id', userId) // hanya log peminjam ini
      .order('created_at', ascending: false);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Aktivitas Peminjam'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchLogs(),
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
              final peminjamNama = peminjaman != null ? peminjaman['nama'] : '-';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.event_note, color: Colors.green),
                  title: Text(log['aktivitas'] ?? '-'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${log['role'] ?? '-'}'),
                      if (peminjaman != null) Text('Peminjam: $peminjamNama'),
                      Text('Tanggal: ${log['created_at'].toString().substring(0, 19)}'),
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
}
