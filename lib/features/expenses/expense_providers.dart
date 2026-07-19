import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firestore_provider.dart';
import '../../features/auth/auth_controller.dart';
import '../../models/expense.dart';
import 'expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final uid = ref.watch(userIdProvider)!;
  final firestore = ref.watch(firestoreProvider);
  return ExpenseRepository(firestore, uid);
});

final expenseListProvider =
    FutureProvider.family<List<Expense>, DateTimeRange>((ref, range) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final snap = await repo
      .stream(start: range.start, end: range.end)
      .first;
  return snap.docs
      .map((d) => Expense.fromJson(d.data() as Map<String, dynamic>, d.id))
      .toList();
});

final expenseSumProvider =
    FutureProvider.family<int, DateTimeRange>((ref, range) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.sumAmount(range.start, range.end);
});
