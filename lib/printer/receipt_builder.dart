import 'package:intl/intl.dart';
import '../models/transaction.dart' as models;
import '../models/resto_profile.dart';

class ReceiptBuilder {
  static final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static List<int> fromTransaction(
      models.Transaction txn, RestoProfile profile) {
    final buf = StringBuffer();
    final w = profile.paperWidth == 80 ? 48 : 32;

    void center(String s) {
      final pad = ((w - s.length) ~/ 2).clamp(0, w);
      buf.writeln(' ' * pad + s);
    }

    void divider() => buf.writeln('─' * w);

    void line(String left, String right) {
      final r = right.length;
      final pad = (w - r - left.length).clamp(1, w);
      buf.writeln(left + ' ' * pad + right);
    }

    center(profile.name.toUpperCase());
    if (profile.address != null && profile.address!.isNotEmpty) {
      center(profile.address!);
    }
    if (profile.phone != null && profile.phone!.isNotEmpty) {
      center('Telp ${profile.phone}');
    }
    buf.writeln();
    divider();

    final dateStr = DateFormat('dd/MM/yy HH:mm').format(txn.createdAt);
    line('No: #${txn.number}', dateStr);
    divider();

    for (final item in txn.items) {
      buf.writeln(item.name);
      final discStr =
          item.discount > 0 ? '(disc ${_fmt.format(item.discount)}) ' : '';
      buf.writeln(
          '  ${item.qty} x ${_fmt.format(item.price)} $discStr${_fmt.format(item.subtotal)}');
    }

    divider();
    line('Subtotal', _fmt.format(txn.subtotal));
    if (txn.discount > 0) {
      line('Diskon', '-${_fmt.format(txn.discount)}');
    }
    line('TOTAL', _fmt.format(txn.total));
    line('Tunai', _fmt.format(txn.paid));
    if (txn.change > 0) {
      line('Kembali', _fmt.format(txn.change));
    }

    buf.writeln();
    if (profile.footerNote != null && profile.footerNote!.isNotEmpty) {
      center(profile.footerNote!);
    }
    buf.writeln();
    buf.writeln();
    buf.writeln();

    return buf.toString().codeUnits;
  }
}
