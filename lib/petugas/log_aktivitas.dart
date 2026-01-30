import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogAktivitasPage extends StatelessWidget {
  const LogAktivitasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Aktivitas')),
      body: FutureBuilder(
        future: supabase
            .from('log_aktivitas')
            .select()
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data as List;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final log = data[i];

              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(log['aktivitas']),
                subtitle: Text(
                  'Role: ${log['role']} • ${log['created_at'].toString().substring(0, 16)}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
