import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../core/services/firestore_provider.dart';
import '../../features/auth/auth_controller.dart';
import '../products/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final uid = ref.watch(userIdProvider)!;
  final firestore = ref.watch(firestoreProvider);
  return ProductRepository(firestore, uid);
});

final productListProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.stream().map((snap) => snap.docs
      .map((d) => Product.fromJson(d.data() as Map<String, dynamic>, d.id))
      .toList());
});

final productProvider = FutureProvider.family<Product?, String>((ref, id) async {
  // For simplicity, filter from list provider
  final products = await ref.watch(productListProvider.future);
  try {
    return products.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});
