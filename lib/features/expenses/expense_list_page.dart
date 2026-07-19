import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/amount_text.dart';
import '../../models/expense.dart';
import '../expenses/expense_providers.dart';

class ExpenseListPage extends ConsumerStatefulWidget {
  const ExpenseListPage({super.key});

  @override
  ConsumerState<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends ConsumerState<ExpenseListPage> {
  DateTime _selected = DateTime.now();

  DateTime get _start =>
      DateTime(_selected.year, _selected.month, 1);
  DateTime get _end =>
      DateTime(_selected.year, _selected.month + 1, 0, 23, 59, 59);

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    final range = DateTimeRange(start: _start, end: _end);
    final expensesAsync = ref.watch(expenseListProvider(range));
    final sumAsync = ref.watch(expenseSumProvider(range));

    return Scaffold(
      appBar: AppBar(title: const Text('Pengeluaran')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  _monthLabel,
                  style: textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () =>
                      setState(() => _selected =
                          DateTime(_selected.year, _selected.month - 1)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () =>
                      setState(() => _selected =
                          DateTime(_selected.year, _selected.month + 1)),
                ),
              ],
            ),
          ),
          sumAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (sum) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                child: Row(
                  children: [
                    Text('Total Pengeluaran',
                        style: textTheme.bodyLarge),
                    const Spacer(),
                    AmountText(
                      amount: sum,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: expensesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada pengeluaran',
                    subtitle: 'Catat pengeluaran bulan ini',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(expenseListProvider(range)),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: expenses.length,
                    itemBuilder: (_, i) =>
                        _ExpenseItem(expense: expenses[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_expense',
        onPressed: () => _add(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String get _monthLabel {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${months[_selected.month]} ${_selected.year}';
  }

  void _add(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddExpenseDialog(),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final Expense expense;

  const _ExpenseItem({required this.expense});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    final dateStr =
        '${expense.date.day}/${expense.date.month}/${expense.date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (expense.category != null)
                  Text(expense.category!,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                if (expense.note != null)
                  Text(expense.note!,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                      maxLines: 2),
                Text(dateStr,
                    style: textTheme.labelSmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          AmountText(
            amount: expense.amount,
            style: textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _catCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _catCtrl.dispose();
    _noteCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Pengeluaran'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amtCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp) *',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  if (int.tryParse(v.trim()) == null || int.parse(v.trim()) <= 0) {
                    return 'Jumlah tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _catCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  hintText: 'Operasional, Belanja, dll',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  hintText: 'Beli gas, bayar listrik, dll',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tanggal'),
                  child: Text(
                    '${_date.day}/${_date.month}/${_date.year}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.save(Expense(
        category: _catCtrl.text.trim().isEmpty
            ? null
            : _catCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
        amount: int.parse(_amtCtrl.text.trim()),
        date: _date,
        createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // error
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
