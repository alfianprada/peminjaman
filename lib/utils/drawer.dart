
import 'package:flutter/material.dart';
import 'package:peminjaman_alat/petugas/dashboard_petugas.dart';

class DrawerPetugas extends StatelessWidget {
  const DrawerPetugas({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('Petugas Bengkel'),
            accountEmail: Text(''),
          ),

          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardPetugas(),
              ),
            ),
          ),
          // menu lain...
        ],
      ),
    );
  }
}
