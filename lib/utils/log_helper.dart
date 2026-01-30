import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> simpanLog({
  required String aktivitas,
  int? peminjamanId,
}) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return;

  // ambil role user
  final userData = await supabase
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

  await supabase.from('log_aktivitas').insert({
    'user_id': user.id,
    'role': userData['role'], // 🔴 PENTING
    'aktivitas': aktivitas,
    'peminjaman_id': peminjamanId,
  });
}
