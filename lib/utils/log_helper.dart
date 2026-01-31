import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper untuk menyimpan log aktivitas sistem
Future<void> simpanLog({
  required String aktivitas,
  int? peminjamanId,
  required String role, // 'peminjam' | 'petugas' | 'admin'
}) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  // ⛔ Pastikan user login
  if (user == null) {
    throw Exception('User belum login, tidak bisa menyimpan log');
  }

  try {
    await supabase.from('log_aktivitas').insert({
      'user_id': user.id,
      'role': role,
      'aktivitas': aktivitas,
      'peminjaman_id': peminjamanId,
      // created_at biarkan default dari database (NOW())
    });
  } catch (e) {
    // 🧠 Bantu debugging (opsional)
    debugPrint('Gagal menyimpan log aktivitas: $e');
    rethrow;
  }
}
