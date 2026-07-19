import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/auth_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  int _paperWidth = 58;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Resto')),
      body: Form(
        key: _formKey,
        child: Row(
          children: [
            // Left Column: Promo / Features
            Expanded(
              flex: 4,
              child: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.star, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Selamat Datang di\nRESTO FLOW FREE',
                      style: textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aplikasi kasir pintar untuk bisnis restoran dan kafe Anda. Didesain secara profesional, mudah digunakan, dan 100% GRATIS tanpa batasan fitur maupun biaya tersembunyi.',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _featureRow(Icons.check_circle, 'Kelola Produk Tanpa Batas', textTheme),
                    const SizedBox(height: 12),
                    _featureRow(Icons.check_circle, 'Catat Pengeluaran & Pemasukan', textTheme),
                    const SizedBox(height: 12),
                    _featureRow(Icons.check_circle, 'Cetak Struk Bluetooth Thermal', textTheme),
                    const SizedBox(height: 12),
                    _featureRow(Icons.check_circle, 'Laporan Keuangan Realtime', textTheme),
                  ],
                ),
              ),
            ),
            // Right Column: Form
            Expanded(
              flex: 5,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                children: [
                  Text('Pengaturan Awal', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Lengkapi profil restoran Anda untuk dicetak pada struk.',
                    style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Resto *'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'No. Telepon'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _footerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Pesan Footer Struk',
                      hintText: 'Misal: Terima kasih telah berkunjung',
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Ukuran Kertas Printer (Thermal)',
                      style: textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _sizeCard(58, '58 mm'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _sizeCard(80, '80 mm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  PrimaryButton(
                    label: 'Simpan Profil & Mulai',
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Text(
          text,
          style: textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _sizeCard(int width, String label) {
    final selected = _paperWidth == width;
    return GestureDetector(
      onTap: () => setState(() => _paperWidth = width),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.print_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color:
                    selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
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
      final uid = ref.read(userIdProvider);
      if (uid == null) throw Exception('Not logged in');
      await FirebaseFirestore.instance
          .doc('users/$uid/profile/resto')
          .set({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        'footerNote': _footerCtrl.text.trim().isEmpty
            ? null
            : _footerCtrl.text.trim(),
        'paperWidth': _paperWidth,
        'useLogo': false,
        'logoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ref.invalidate(profileProvider);
    } catch (e) {
      // TODO: show error snackbar
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
