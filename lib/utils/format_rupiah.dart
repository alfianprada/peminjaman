import 'package:intl/intl.dart';

String formatRupiah(num value) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2,
  );

  return formatter.format(value);
}
