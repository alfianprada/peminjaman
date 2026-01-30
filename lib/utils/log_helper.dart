import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> simpanLog({
  required String aktivitas,
  int? peminjamanId,
}) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  await supabase.from('log_aktivitas').insert({
    'user_id': user?.id,
    'role': user?.userMetadata?['role'] ?? 'unknown',
    'aktivitas': aktivitas,
    'peminjaman_id': peminjamanId,
  });
}
