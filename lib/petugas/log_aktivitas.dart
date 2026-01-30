import 'package:flutter/material.dart';
import 'package:peminjaman_alat/utils/drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogAktivitasPage extends StatelessWidget {
  final String role;

  const LogAktivitasPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Aktivitas')),
      drawer: const DrawerPetugas(), 
      body: FutureBuilder(
        future: supabase
            .from('log_aktivitas')
            .select()
            .eq('role', role)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data as List;

          if (data.isEmpty) {
            return const Center(child: Text('Belum ada aktivitas'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final log = data[i];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(log['aktivitas']),
                subtitle: Text(
                  'Peminjaman ID: ${log['peminjaman_id'] ?? '-'}\n'
                  '${log['created_at'].toString().substring(0, 16)}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
