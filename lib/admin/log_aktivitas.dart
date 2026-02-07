import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:peminjaman_alat/admin/drawer_dashboard.dart';

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
              if (!context.mounted) return;

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  }
});

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
                    'Log Aktivitas',
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
