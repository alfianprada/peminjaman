import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class DashboardPeminjam extends StatefulWidget {
  const DashboardPeminjam({super.key});

  @override
  State<DashboardPeminjam> createState() => _DashboardPeminjamState();
}

class _DashboardPeminjamState extends State<DashboardPeminjam> {
  final supabase = Supabase.instance.client;

  String namaPeminjam = '';
  List kategoriList = [];
  List alatList = [];
  String searchText = '';

  int? kategoriAktif;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNama();
    fetchKategori();
    fetchAlat();
  }

  // ================= LOAD USER =================
  Future<void> _loadNama() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('users')
        .select('nama')
        .eq('id', user.id)
        .single();

    setState(() => namaPeminjam = data['nama'] ?? 'Peminjam');
  }

  // ================= FETCH =================
  Future<void> fetchKategori() async {
    kategoriList = await supabase
        .from('kategori')
        .select()
        .order('nama_kategori');
    setState(() {});
  }

  Future<void> fetchAlat() async {
    setState(() => isLoading = true);

    alatList = kategoriAktif == null
        ? await supabase
            .from('alat')
            .select('id, nama_alat, stok, kondisi, kategori_id')
            .order('nama_alat')
        : await supabase
            .from('alat')
            .select('id, nama_alat, stok, kondisi, kategori_id')
            .eq('kategori_id', kategoriAktif!)
            .order('nama_alat');

    setState(() => isLoading = false);
  }

  // ================= UI =================
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
                    namaPeminjam,
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
                      'Peminjam',
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

            // 🔔 NOTIFIKASI
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications, color: Colors.white),
            ),
          ],
        ),
      ),
    ),
  ),


),

      // ================= BODY =================
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _searchBox(),
                  const SizedBox(height: 16),
            const Text('Kategori Alat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ===== KATEGORI =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  kategoriChip('Semua', null),
                  ...kategoriList.map(
                    (k) => kategoriChip(k['nama_kategori'], k['id']),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Daftar Alat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: alatList.length,
                      itemBuilder: (_, i) => alatCard(alatList[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= WIDGET =================
  Widget kategoriChip(String label, int? id) {
    final aktif = kategoriAktif == id;
    return GestureDetector(
      onTap: () {
        setState(() => kategoriAktif = id);
        fetchAlat();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: aktif ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(color: aktif ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget alatCard(Map alat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.build, color: Colors.blue, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alat['nama_alat'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Kondisi: ${alat['kondisi']}'),
              ],
            ),
          ),
          Column(
            children: [
              const Text('Stok'),
              Text(alat['stok'].toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchText = value.toLowerCase()),
        decoration: const InputDecoration(
          icon: Icon(Icons.search),
          hintText: 'Cari alat...',
          border: InputBorder.none,
        ),
      ),
    );
  }
}
