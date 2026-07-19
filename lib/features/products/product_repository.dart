import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  ProductRepository(this._firestore, this._uid);

  CollectionReference get _col =>
      _firestore.collection('users/$_uid/products');

  Future<List<Product>> getAll() async {
    final snap = await _col
        .where('archived', isEqualTo: false)
        .orderBy('name')
        .get();
    return snap.docs
        .map((d) => Product.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Stream<QuerySnapshot> stream() =>
      _col.where('archived', isEqualTo: false).orderBy('name').snapshots();

  Future<DocumentReference> add(Product product) async {
    return await _col.add(product.toJson());
  }

  Future<void> save(Product product) async {
    await _col.doc(product.id!).update(product.toJson());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).update({'archived': true});
  }

  Future<void> toggleReady(String id, bool ready) async {
    await _col.doc(id).update({'ready': ready, 'updatedAt': DateTime.now()});
  }
}
