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
  final _formKey = GlobalKey<FormState>();

  final _namaC = TextEditingController();
  final _alamatC = TextEditingController();
  final _telpC = TextEditingController();
  final _ketC = TextEditingController();

  DateTime? _tglPinjam;
  DateTime? _tglKembali;
  bool _loading = false;

  Future<bool> _cekStokAlat() async {
  final supabase = Supabase.instance.client;

  for (final item in widget.items) {
    final alat = await supabase
        .from('alat')
        .select('stok')
        .eq('id', item.alatId)
        .single();

    final stok = alat['stok'] as int;

    if (stok < item.jumlah) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok ${item.nama} tidak mencukupi (tersisa $stok)',
          ),
        ),
      );
      return false;
    }
  }
  return true;
}


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
  if (!_formKey.currentState!.validate()) return;

  if (_tglPinjam == null || _tglKembali == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tanggal wajib diisi')),
    );
    return;
  }

  if (_tglPinjam!.isAtSameMomentAs(_tglKembali!)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tanggal pinjam dan kembali tidak boleh sama'),
      ),
    );
    return;
  }

  // 🔴 CEK STOK DI SINI
  final stokAman = await _cekStokAlat();
  if (!stokAman) return;

  setState(() => _loading = true);


    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser!;

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

      for (final item in widget.items) {
  // insert detail
  await supabase.from('detail_peminjaman').insert({
    'peminjaman_id': peminjamanId,
    'alat_id': item.alatId,
    'jumlah': item.jumlah,
  });

  // kurangi stok alat
  await supabase.rpc('kurangi_stok_alat', params: {
    'p_alat_id': item.alatId,
    'p_jumlah': item.jumlah,
  });
}


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
        const SnackBar(content: Text('Terjadi kesalahan')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Peminjaman')),
      body: Form(
        key: _formKey,
        child: ListView(
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

            _input(
              controller: _namaC,
              label: 'Nama',
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama wajib diisi' : null,
            ),

            _input(
              controller: _alamatC,
              label: 'Alamat',
              validator: (v) =>
                  v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
            ),

            _input(
              controller: _telpC,
              label: 'Nomor Telepon',
              keyboard: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Nomor telepon wajib diisi';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                  return 'Nomor telepon harus berupa angka';
                }
                if (v.length < 10) {
                  return 'Nomor telepon minimal 10 digit';
                }
                return null;
              },
            ),

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

            _input(
            controller: _ketC,
            label: 'Keterangan Meminjam',
            maxLines: 3,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Keterangan tidak boleh kosong';
              }
              return null;
            },
          ),

            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('AJUKAN PEMINJAMAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: validator,
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

