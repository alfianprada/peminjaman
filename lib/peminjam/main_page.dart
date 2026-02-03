import 'package:flutter/material.dart';
import 'dashboard_peminjam.dart';
import 'daftar_alat.dart';
import 'peminjaman_saya.dart';
import 'profile_peminjam.dart';

class PeminjamMainPage extends StatefulWidget {
  const PeminjamMainPage({super.key});

  @override
  State<PeminjamMainPage> createState() => _PeminjamMainPageState();
}

class _PeminjamMainPageState extends State<PeminjamMainPage> {
  int _index = 0;

  final pages = const [
    DashboardPeminjam(),
    PeminjamanPage(),        // daftar alat
    PeminjamanSayaPage(),
    ProfilePeminjamPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Alat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Peminjaman',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
