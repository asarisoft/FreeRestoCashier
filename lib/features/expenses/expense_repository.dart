import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/expense.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  ExpenseRepository(this._firestore, this._uid);

  CollectionReference get _col =>
      _firestore.collection('users/$_uid/expenses');

  Stream<QuerySnapshot> stream({DateTime? start, DateTime? end}) {
    Query q = _col.orderBy('date', descending: true);
    if (start != null) q = q.where('date', isGreaterThanOrEqualTo: start);
    if (end != null) q = q.where('date', isLessThanOrEqualTo: end);
    return q.snapshots();
  }

  Future<void> save(Expense expense) async {
    await _col.add(expense.toJson());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<int> sumAmount(DateTime start, DateTime end) async {
    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();
    return snap.docs.fold<int>(
        0, (total, d) => total + ((d.data() as Map<String, dynamic>)['amount'] as int? ?? 0));
  }
}
