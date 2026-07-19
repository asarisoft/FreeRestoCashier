import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/product.dart';
import '../../models/transaction.dart' as models;
import '../../models/transaction_item.dart';
import '../../models/resto_profile.dart';
import '../../printer/printer_service.dart';
import '../../printer/receipt_builder.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/products/product_providers.dart';
import '../pos/cart_provider.dart';
import '../reports/report_providers.dart';

class PosPage extends ConsumerWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final cart = ref.watch(cartProvider);
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Kasir')),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          if (isWide) return _wideLayout(context, ref, productsAsync, cart);
          return _compactLayout(context, ref, productsAsync, cart);
        },
      ),
    );
  }

  Widget _compactLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Product>> productsAsync,
    List<TransactionItem> cart,
  ) {
    final cartNotif = ref.read(cartProvider.notifier);
    return Column(
      children: [
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (products) =>
                _productGrid(context, ref, products, cartNotif),
          ),
        ),
        if (cart.isNotEmpty)
          GestureDetector(
            onTap: () => _showCartSheet(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Badge(
                    label: Text(
                        '${cart.fold(0, (s, i) => s + i.qty)}'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  const SizedBox(width: 12),
                  Text('${cart.fold(0, (s, i) => s + i.qty)} item',
                      style: AppTypography.textTheme.bodyMedium),
                  const Spacer(),
                  AmountText(
                    amount: cart.fold(0, (s, i) => s + i.subtotal),
                    style: AppTypography.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.expand_less),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _wideLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Product>> productsAsync,
    List<TransactionItem> cart,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (products) => _productGrid(
                context, ref, products, ref.read(cartProvider.notifier)),
          ),
        ),
        SizedBox(
          width: 360,
          child: _CartPanel(cart: cart, ref: ref),
        ),
      ],
    );
  }

  Widget _productGrid(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
    CartNotifier cartNotif,
  ) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return LayoutBuilder(
      builder: (_, constraints) {
        final cols = isWide
            ? (constraints.maxWidth ~/ 160).clamp(3, 5)
            : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => _PosProductCard(
            product: products[i],
            onTap: () => cartNotif.addItem(products[i]),
          ),
        );
      },
    );
  }

  void _showCartSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: _CartPanel(cart: ref.watch(cartProvider), ref: ref),
      ),
    );
  }
}

class _PosProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _PosProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    return GestureDetector(
      onTap: product.ready ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: product.ready ? AppColors.border : Colors.red.shade100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!product.ready)
                  const Icon(Icons.block, size: 14, color: AppColors.error),
              ],
            ),
            const Spacer(),
            AmountText(
              amount: product.price,
              style: textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPanel extends ConsumerWidget {
  final List<TransactionItem> cart;
  final WidgetRef ref;

  const _CartPanel({required this.cart, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final textTheme = AppTypography.textTheme;
    final subtotal = cart.fold(0, (s, i) => s + i.subtotal);
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Column(
      children: [
        if (!isWide)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Keranjang', style: textTheme.titleLarge),
          ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Text('Keranjang kosong',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.length,
                  itemBuilder: (_, i) => _CartItemRow(
                    index: i,
                    item: cart[i],
                    notifier: ref.read(cartProvider.notifier),
                  ),
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: textTheme.titleLarge),
                  AmountText(
                    amount: subtotal,
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Bayar',
                icon: Icons.payment,
                onPressed:
                    cart.isEmpty ? null : () => _checkout(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _checkout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const CheckoutDialog(),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final int index;
  final TransactionItem item;
  final CartNotifier notifier;

  const _CartItemRow({
    required this.index,
    required this.item,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _qtyBtn(Icons.remove_circle_outline, () {
                      notifier.updateQty(index, item.qty - 1);
                    }),
                    const SizedBox(width: 8),
                    Text('${item.qty}', style: textTheme.titleMedium),
                    const SizedBox(width: 8),
                    _qtyBtn(Icons.add_circle_outline, () {
                      notifier.updateQty(index, item.qty + 1);
                    }),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(
                amount: item.subtotal,
                style: textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (item.discount > 0)
                GestureDetector(
                  onTap: () =>
                      _editDiscount(context, item),
                  child: Text('disc: ${item.discount}',
                      style: textTheme.labelSmall
                          ?.copyWith(color: AppColors.error)),
                ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => notifier.removeAt(index),
            child: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _editDiscount(BuildContext context, TransactionItem item) {
    final ctrl = TextEditingController(text: item.discount.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Diskon Item'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Diskon (Rp)',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () {
                final d = int.tryParse(ctrl.text) ?? 0;
                notifier.updateDiscount(
                    index, d.clamp(0, item.price));
                Navigator.pop(context);
              },
              child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Icon(icon, size: 22, color: AppColors.primary),
      );
}

class CheckoutDialog extends ConsumerStatefulWidget {
  const CheckoutDialog({super.key});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  final _paidCtrl = TextEditingController();
  final _discCtrl = TextEditingController();
  String _method = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _paidCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  int get _subtotal =>
      ref.read(cartProvider).fold(0, (s, i) => s + i.subtotal);
  int get _discount => int.tryParse(_discCtrl.text) ?? 0;
  int get _total => (_subtotal - _discount).clamp(0, _subtotal);
  int get _paid => int.tryParse(_paidCtrl.text) ?? 0;
  int get _change => (_paid - _total).clamp(0, _paid);

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    final isWide = MediaQuery.of(context).size.width >= 600;
    return AlertDialog(
      title: const Text('Pembayaran'),
      content: SizedBox(
        width: isWide ? 400 : double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _row('Subtotal', _subtotal, textTheme),
              TextField(
                controller: _discCtrl,
                decoration: const InputDecoration(
                  labelText: 'Diskon (Rp)',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const Divider(height: 24),
              _row('Total', _total, textTheme, bold: true),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(labelText: 'Metode'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                  DropdownMenuItem(value: 'card', child: Text('Kartu')),
                ],
                onChanged: (v) => setState(() => _method = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paidCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dibayar (Rp)',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              if (_change > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _row('Kembali', _change, textTheme),
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
          onPressed: _saving || _total <= 0 ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan & Cetak'),
        ),
      ],
    );
  }

  Widget _row(String label, int amount, TextTheme tt,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: bold
                  ? tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)
                  : tt.bodyLarge),
          AmountText(
            amount: amount,
            style: (bold ? tt.titleMedium : tt.bodyLarge)
                ?.copyWith(fontWeight: bold ? FontWeight.w700 : null),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_paid < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang dibayar kurang dari total')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final items = ref.read(cartProvider);
      final notif = ref.read(cartProvider.notifier);
      final txnRepo = ref.read(transactionRepositoryProvider);
      final profile = await ref.read(profileProvider.future);
      final number = await txnRepo.getNextNumber();
      final profit =
          items.fold(0, (s, i) => s + i.totalProfit) - _discount;

      final txn = models.Transaction(
        number: number,
        items: items,
        subtotal: _subtotal,
        discount: _discount,
        total: _total,
        paid: _paid,
        change: _change,
        paymentMethod: _method,
        profit: profit,
        createdAt: DateTime.now(),
      );

      await txnRepo.save(txn);

      if (profile != null) {
        _tryPrint(txn, profile);
      }

      notif.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil disimpan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _tryPrint(
      models.Transaction txn, RestoProfile profile) async {
    try {
      final bytes = ReceiptBuilder.fromTransaction(txn, profile);
      final printer = PrinterService();
      if (printer.isConnected) {
        await printer.printBytes(bytes);
      }
    } catch (_) {}
  }
}
