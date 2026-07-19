import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/amount_text.dart';
import '../../models/product.dart';
import '../../models/transaction.dart' as models;
import '../../models/transaction_item.dart';
import '../../models/resto_profile.dart';
import '../../printer/printer_service.dart';
import '../../printer/receipt_builder.dart';
import '../../features/products/product_providers.dart';
import '../pos/cart_provider.dart';
import '../pos/transaction_repository.dart';
import '../auth/auth_controller.dart';
import '../reports/report_providers.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  String _selectedCategory = 'All Menu';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final cart = ref.watch(cartProvider);
    final isWide = MediaQuery.of(context).size.width >= 768; // Tablet breakpoint

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isWide ? null : AppBar(title: const Text('Kasir')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          // Extract categories
          final categories = ['All Menu'];
          for (final p in products) {
            if (p.category != null && p.category!.isNotEmpty && !categories.contains(p.category)) {
              categories.add(p.category!);
            }
          }

          // Filter products
          final filteredProducts = _selectedCategory == 'All Menu'
              ? products
              : products.where((p) => p.category == _selectedCategory).toList();

          if (isWide) {
            return _buildTabletLayout(categories, filteredProducts, cart);
          } else {
            return _buildMobileLayout(categories, filteredProducts, cart);
          }
        },
      ),
    );
  }

  Widget _buildTabletLayout(List<String> categories, List<Product> products, List<TransactionItem> cart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories Sidebar
        Container(
          width: 220,
          color: AppColors.background,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Choose Menu', style: AppTypography.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat == _selectedCategory;
                    return _CategoryCard(
                      label: cat,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedCategory = cat),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Main Products
        Expanded(
          child: _ProductGrid(products: products, cart: cart, isWide: true),
        ),
        // Cart Sidebar
        Container(
          width: 380,
          color: AppColors.surface,
          child: _CartPanel(cart: cart),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<String> categories, List<Product> products, List<TransactionItem> cart) {
    return Column(
      children: [
        // Horizontal Categories
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _CategoryCard(
                  label: cat,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedCategory = cat),
                ),
              );
            },
          ),
        ),
        Expanded(child: _ProductGrid(products: products, cart: cart, isWide: false)),
        // Minimal Cart Summary at bottom
        if (cart.isNotEmpty)
          GestureDetector(
            onTap: () => _showMobileCart(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: AppColors.onPrimary),
                  const SizedBox(width: 12),
                  Text('${cart.fold(0, (s, i) => s + i.qty)} Items',
                      style: AppTypography.textTheme.titleMedium?.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  AmountText(
                    amount: cart.fold(0, (s, i) => s + i.subtotal),
                    style: AppTypography.textTheme.titleMedium?.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _CartPanel(cart: ref.watch(cartProvider)),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Text(
          label,
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final List<TransactionItem> cart;
  final bool isWide;

  const _ProductGrid({required this.products, required this.cart, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.only(
        top: isWide ? 76 : 16,
        left: isWide ? 24 : 16,
        right: isWide ? 24 : 16,
        bottom: 24,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final cartItem = cart.where((item) => item.productId == product.id).firstOrNull;
        return _PosProductCard(
          product: product,
          cartQty: cartItem?.qty ?? 0,
        );
      },
    );
  }
}

class _PosProductCard extends ConsumerWidget {
  final Product product;
  final int cartQty;

  const _PosProductCard({required this.product, required this.cartQty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme;
    final notif = ref.read(cartProvider.notifier);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Placeholder
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7E0), // Soft yellow background for placeholder
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(
                child: Icon(Icons.fastfood, size: 48, color: Color(0xFFFFD568)),
              ),
            ),
          ),
          // Content
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Placeholder for description
                  Text(
                    'Delicious and freshly made',
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AmountText(
                        amount: product.price,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.price,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Add / Counter control
                      if (cartQty == 0)
                        InkWell(
                          onTap: product.ready ? () => notif.addItem(product) : null,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 18, color: AppColors.onPrimary),
                          ),
                        )
                      else
                        Row(
                          children: [
                            InkWell(
                              onTap: () => notif.updateQty(
                                  ref.read(cartProvider).indexWhere((i) => i.productId == product.id),
                                  cartQty - 1),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.border,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('$cartQty', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            InkWell(
                              onTap: () => notif.updateQty(
                                  ref.read(cartProvider).indexWhere((i) => i.productId == product.id),
                                  cartQty + 1),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, size: 16, color: AppColors.onPrimary),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPanel extends ConsumerWidget {
  final List<TransactionItem> cart;

  const _CartPanel({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme;
    final subtotal = cart.fold(0, (s, i) => s + i.subtotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 16),
          child: Text('Order Detail', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Text('Keranjang kosong',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const Divider(height: 32),
                  itemBuilder: (_, i) => _CartItemRow(
                    index: i,
                    item: cart[i],
                    notifier: ref.read(cartProvider.notifier),
                  ),
                ),
        ),
        // Total Box
        if (cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Items (${cart.fold(0, (s, i) => s + i.qty)})', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  AmountText(amount: subtotal, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  AmountText(
                    amount: subtotal,
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: cart.isEmpty ? null : () => _checkout(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size(double.infinity, 56),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Proceed Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              if (item.discount > 0)
                Text('Disc: Rp ${item.discount}', style: textTheme.labelSmall?.copyWith(color: AppColors.error)),
              const SizedBox(height: 8),
              // Notes button mockup
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_note, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text('Notes', style: textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('x${item.qty}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AmountText(
              amount: item.subtotal,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
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
                  hintText: '0',
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
                  hintText: '0',
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
      final profileAsync = ref.read(profileProvider);
      
      final number = await txnRepo.getNextNumber();
      final profit = items.fold(0, (s, i) => s + i.totalProfit) - _discount;

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

      final profile = profileAsync.valueOrNull;
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
