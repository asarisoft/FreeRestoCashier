import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/product.dart';
import '../../features/auth/auth_controller.dart';
import '../products/product_providers.dart';
import 'product_image_service.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormPage({super.key, this.product});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _hppCtrl = TextEditingController();
  String? _imageUrl;
  bool _ready = true;
  bool _saving = false;

  final _imageService = ProductImageService();
  XFile? _pickedFile;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl.text = p?.name ?? '';
    _categoryCtrl.text = p?.category ?? '';
    _priceCtrl.text = p != null ? p.price.toString() : '';
    _hppCtrl.text = p != null ? p.hpp.toString() : '';
    _imageUrl = p?.imageUrl;
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
            GestureDetector(
              onTap: _saving ? null : _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    style: _imageUrl == null ? BorderStyle.solid : BorderStyle.none,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                      child: _pickedFile != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_pickedFile!.path),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _pickedFile = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _imageUrl != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (_, __, ___) => const Icon(
                                    Icons.broken_image, size: 48),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _imageUrl = null);
                                    _pickedFile = null;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text('Tap untuk tambah foto',
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 20),
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

  Future<void> _pickImage() async {
    final file = await _imageService.pickImage();
    if (file == null) return;
    setState(() {
      _pickedFile = file;
      _imageUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final uid = ref.read(userIdProvider)!;
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
        imageUrl: widget.product?.imageUrl,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );

      String? savedId = product.id;
      if (savedId == null) {
        final docRef = await repo.add(product);
        savedId = docRef.id;
      } else {
        await repo.save(product);
      }

      if (_pickedFile != null) {
        if (widget.product?.imageUrl != null) {
          await _imageService.delete(uid, savedId);
        }
        final url = await _imageService.upload(uid, savedId, _pickedFile!);
        await FirebaseFirestore.instance
            .doc('users/$uid/products/$savedId')
            .update({'imageUrl': url, 'updatedAt': now});
      }

      ref.invalidate(productListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
