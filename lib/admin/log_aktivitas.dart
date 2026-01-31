import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogAktivitasPage extends StatelessWidget {
  const LogAktivitasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

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
        // Ambil semua log
        future: supabase
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
                  leading: const Icon(Icons.event_note, color: Colors.blue),
                  title: Text(log['aktivitas'] ?? '-'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${log['role'] ?? '-'}'),
                      Text('Peminjam: $peminjamNama'),
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
