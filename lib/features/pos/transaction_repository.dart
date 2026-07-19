import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transaction.dart' as models;

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  TransactionRepository(this._firestore, this._uid);

  CollectionReference get _col =>
      _firestore.collection('users/$_uid/transactions');

  CollectionReference get _counter =>
      _firestore.collection('users/$_uid/counters');

  Future<int> getNextNumber() async {
    final counterRef = _counter.doc('transactions');
    final result =
        await _firestore.runTransaction((tx) async {
      final doc = await tx.get(counterRef);
      final data = doc.data() as Map<String, dynamic>?;
      final next = ((data?['value'] as int?) ?? 0) + 1;
      tx.set(counterRef, {'value': next});
      return next;
    });
    return result;
  }

  Future<void> save(models.Transaction txn) async {
    await _col.add(txn.toJson());
  }

  Stream<QuerySnapshot> stream({DateTime? start, DateTime? end}) {
    Query q = _col.orderBy('createdAt', descending: true);
    if (start != null) q = q.where('createdAt', isGreaterThanOrEqualTo: start);
    if (end != null) q = q.where('createdAt', isLessThanOrEqualTo: end);
    return q.snapshots();
  }

  Future<models.Transaction?> get(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return models.Transaction.fromJson(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<int> sumProfit(DateTime start, DateTime end) async {
    final snap = await _col
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .get();
    return snap.docs.fold<int>(
        0, (s, d) => s + ((d.data() as Map<String, dynamic>)['profit'] as int? ?? 0));
  }

  Future<int> sumTotal(DateTime start, DateTime end) async {
    final snap = await _col
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .get();
    return snap.docs.fold<int>(
        0, (s, d) => s + ((d.data() as Map<String, dynamic>)['total'] as int? ?? 0));
  }

  Future<void> markPrinted(String id) async {
    await _col.doc(id).update({'printedAt': DateTime.now()});
  }
}
