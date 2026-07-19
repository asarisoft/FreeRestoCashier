import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firestore_provider.dart';
import '../../features/auth/auth_controller.dart';
import '../../models/transaction.dart';
import '../../features/expenses/expense_providers.dart';
import '../../features/pos/transaction_repository.dart';
import 'report_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final uid = ref.watch(userIdProvider)!;
  final firestore = ref.watch(firestoreProvider);
  return TransactionRepository(firestore, uid);
});

final reportSummaryProvider =
    FutureProvider.family<ReportSummary, DateTimeRange>((ref, range) async {
  final txnRepo = ref.watch(transactionRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);

  final revenue = await txnRepo.sumTotal(range.start, range.end);
  final profit = await txnRepo.sumProfit(range.start, range.end);
  final expense = await expenseRepo.sumAmount(range.start, range.end);

  final snap = await txnRepo.stream(start: range.start, end: range.end).first;
  final count = snap.docs.length;

  return ReportSummary(
    totalRevenue: revenue,
    totalExpense: expense,
    totalProfit: profit - expense,
    transactionCount: count,
    averagePerTransaction: count > 0 ? revenue ~/ count : 0,
  );
});

final recentTransactionsProvider =
    StreamProvider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.stream().map((snap) => snap.docs
      .map((d) =>
          Transaction.fromJson(d.data() as Map<String, dynamic>, d.id))
      .toList());
});
