import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/amount_text.dart';
import '../../models/transaction.dart' as models;
import '../../printer/printer_service.dart';
import '../../printer/receipt_builder.dart';
import '../../features/auth/auth_controller.dart';
import '../reports/report_providers.dart';
import '../reports/report_repository.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  int _tab = 0;

  DateTimeRange get _range {
    final now = DateTime.now();
    if (_tab == 0) {
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    }
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    final range = _range;
    final summaryAsync = ref.watch(reportSummaryProvider(range));
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tab == 0 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('Hari Ini', style: textTheme.bodyMedium?.copyWith(
                        fontWeight: _tab == 0 ? FontWeight.bold : FontWeight.normal,
                        color: _tab == 0 ? AppColors.onPrimary : AppColors.textSecondary,
                      )),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tab == 1 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('Bulan Ini', style: textTheme.bodyMedium?.copyWith(
                        fontWeight: _tab == 1 ? FontWeight.bold : FontWeight.normal,
                        color: _tab == 1 ? AppColors.onPrimary : AppColors.textSecondary,
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          summaryAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error: $e')),
            data: (s) => _SummaryCards(summary: s),
          ),
          const SizedBox(height: 24),
          Text('Transaksi Terbaru',
              style: textTheme.titleMedium),
          const SizedBox(height: 12),
          recentAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error: $e')),
            data: (txns) {
              if (txns.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi',
                );
              }
              return Column(
                children: txns
                    .take(20)
                    .map((t) => _TransactionRow(
                          txn: t,
                          onReprint: () => _reprint(t),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _reprint(models.Transaction txn) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    try {
      final bytes = ReceiptBuilder.fromTransaction(txn, profile);
      final printer = PrinterService();
      if (printer.isConnected) {
        await printer.printBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Struk dicetak ulang')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Printer tidak terhubung')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal cetak: $e')),
        );
      }
    }
  }
}

class _SummaryCards extends StatelessWidget {
  final ReportSummary summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    return LayoutBuilder(
      builder: (_, constraints) {
        final isWide = constraints.maxWidth >= 500;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _card(
              'Omzet',
              summary.totalRevenue,
              Icons.trending_up,
              AppColors.success,
              isWide, textTheme,
            ),
            _card(
              'Pengeluaran',
              summary.totalExpense,
              Icons.trending_down,
              AppColors.error,
              isWide, textTheme,
            ),
            _card(
              'Laba Bersih',
              summary.totalProfit,
              Icons.account_balance_wallet,
              summary.totalProfit >= 0
                  ? AppColors.success
                  : AppColors.error,
              isWide, textTheme,
            ),
            _card(
              'Transaksi',
              summary.transactionCount,
              Icons.receipt,
              AppColors.primary,
              isWide, textTheme,
              isCount: true,
            ),
          ],
        );
      },
    );
  }

  Widget _card(String label, int value, IconData icon, Color color,
      bool isWide, TextTheme tt,
      {bool isCount = false}) {
    return SizedBox(
      width: isWide ? 220 : double.infinity,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(label,
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            isCount
                ? Text('$value',
                    style: tt.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700))
                : AmountText(
                    amount: value,
                    style: tt.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final models.Transaction txn;
  final VoidCallback onReprint;

  const _TransactionRow(
      {required this.txn, required this.onReprint});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    final dateStr =
        '${txn.createdAt.day}/${txn.createdAt.month} ${txn.createdAt.hour.toString().padLeft(2, '0')}:${txn.createdAt.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${txn.number} — $dateStr',
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${txn.items.length} item · ${txn.paymentMethod}',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          AmountText(
            amount: txn.total,
            style: textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.print_outlined, size: 20),
            onPressed: onReprint,
            tooltip: 'Cetak ulang',
          ),
        ],
      ),
    );
  }
}
