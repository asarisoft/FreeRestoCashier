import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../models/transaction_item.dart';

class CartNotifier extends Notifier<List<TransactionItem>> {
  @override
  List<TransactionItem> build() => [];

  int get subtotal =>
      state.fold(0, (sum, i) => sum + i.subtotal);
  int get itemCount => state.fold(0, (sum, i) => sum + i.qty);

  void addItem(Product product) {
    final existing = state.indexWhere(
        (i) => i.productId == product.id && i.discount == 0);
    if (existing >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == existing) state[i].copyWith(qty: state[i].qty + 1) else state[i],
      ];
    } else {
      state = [...state, TransactionItem.fromProduct(product)];
    }
  }

  void updateQty(int index, int qty) {
    if (qty <= 0) {
      removeAt(index);
      return;
    }
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(qty: qty) else state[i],
    ];
  }

  void updateDiscount(int index, int discount) {
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(discount: discount) else state[i],
    ];
  }

  void removeAt(int index) {
    state = [...state.take(index), ...state.skip(index + 1)];
  }

  void clear() => state = [];
}

final cartProvider = NotifierProvider<CartNotifier, List<TransactionItem>>(
  CartNotifier.new,
);
