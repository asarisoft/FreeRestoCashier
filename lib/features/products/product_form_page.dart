import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/product.dart';
import '../products/product_providers.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormPage({super.key, this.product});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _hppCtrl;
  late bool _ready;
  bool _saving = false;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _hppCtrl =
        TextEditingController(text: p != null ? p.hpp.toString() : '');
    _ready = p?.ready ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _hppCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Produk *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                hintText: 'Makanan, Minuman, dll',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Harga Jual (Rp) *',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                if (int.tryParse(v.trim()) == null) return 'Angka tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hppCtrl,
              decoration: const InputDecoration(
                labelText: 'HPP (Rp)',
                hintText: '0',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text('Status Ready', style: textTheme.bodyLarge),
              subtitle: Text(
                _ready ? 'Produk siap dijual' : 'Produk tidak tersedia',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              value: _ready,
              onChanged: (v) => setState(() => _ready = v),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: _editing ? 'Simpan Perubahan' : 'Tambah Produk',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final now = DateTime.now();
      final product = Product(
        id: widget.product?.id,
        name: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
        price: int.parse(_priceCtrl.text.trim()),
        hpp: _hppCtrl.text.trim().isEmpty
            ? 0
            : int.parse(_hppCtrl.text.trim()),
        ready: _ready,
        archived: widget.product?.archived ?? false,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );
      await repo.save(product);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // TODO: error snackbar
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
