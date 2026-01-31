import 'package:flutter/material.dart';
import 'package:peminjaman_alat/utils/log_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:peminjaman_alat/models/keranjang_items.dart';

class AjukanPeminjamanPage extends StatefulWidget {
  final List<KeranjangItem> items;

  const AjukanPeminjamanPage({
    super.key,
    required this.items,
  });


  @override
  State<AjukanPeminjamanPage> createState() => _AjukanPeminjamanPageState();
}

class _AjukanPeminjamanPageState extends State<AjukanPeminjamanPage> {
  final _namaC = TextEditingController();
  final _alamatC = TextEditingController();
  final _telpC = TextEditingController();
  final _ketC = TextEditingController();

  DateTime? _tglPinjam;
  DateTime? _tglKembali;
  bool _loading = false;

  Future<void> _pickDate(bool isPinjam) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isPinjam) {
          _tglPinjam = date;
        } else {
          _tglKembali = date;
        }
      });
    }
  }

  Future<void> _submit() async {
  if (_namaC.text.isEmpty ||
      _alamatC.text.isEmpty ||
      _telpC.text.isEmpty ||
      _tglPinjam == null ||
      _tglKembali == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lengkapi semua data')),
    );
    return;
  }

  setState(() => _loading = true);

  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser!;
    
    // 1️⃣ INSERT PEMINJAMAN (STATUS PENDING)
    final peminjaman = await supabase
        .from('peminjaman')
        .insert({
          'user_id': user.id,
          'nama': _namaC.text,
          'alamat': _alamatC.text,
          'no_telepon': _telpC.text,
          'tanggal_pinjam': _tglPinjam!.toIso8601String(),
          'tanggal_kembali_rencana': _tglKembali!.toIso8601String(),
          'keterangan': _ketC.text,
          'status': 'pending',
        })
        .select()
        .single();

    final int peminjamanId = peminjaman['id'];

    // 2️⃣ INSERT DETAIL PEMINJAMAN
    for (final item in widget.items) {
      await supabase.from('detail_peminjaman').insert({
        'peminjaman_id': peminjamanId,
        'alat_id': item.alatId,
        'jumlah': item.jumlah,
      });
    }

    // 3️⃣ SIMPAN LOG PEMINJAM
    await simpanLog(
      aktivitas: 'Mengajukan peminjaman',
      peminjamanId: peminjamanId,
      role: 'peminjam',
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peminjaman berhasil diajukan')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan')),
    );
  } finally {
    setState(() => _loading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Peminjaman')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
  'Alat Dipinjam',
  style: TextStyle(fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),

...widget.items.map((e) => Card(
  child: ListTile(
    title: Text(e.nama),
    trailing: Text('x${e.jumlah}'),
  ),
)),
const SizedBox(height: 16),

          _input(_namaC, 'Nama'),
          _input(_alamatC, 'Alamat'),
          _input(_telpC, 'Nomor Telepon', keyboard: TextInputType.phone),
          _dateField(
            'Tanggal Pinjam',
            _tglPinjam,
            () => _pickDate(true),
          ),
          _dateField(
            'Tanggal Dikembalikan',
            _tglKembali,
            () => _pickDate(false),
          ),
          _input(_ketC, 'Keterangan Meminjam', maxLines: 3),

          const SizedBox(height: 24),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('AJUKAN PEMINJAMAN'),
            ),
          )
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            date == null
                ? 'Pilih tanggal'
                : '${date.day}-${date.month}-${date.year}',
          ),
        ),
      ),
    );
 }
}

