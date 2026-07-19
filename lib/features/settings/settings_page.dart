import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/resto_profile.dart';
import '../../features/auth/auth_controller.dart';

import '../settings/settings_providers.dart';
import 'printer_pairing_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Setting')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profil Resto', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _infoRow('Nama', profile.name, textTheme),
                    if (profile.address != null)
                      _infoRow('Alamat', profile.address!, textTheme),
                    if (profile.phone != null)
                      _infoRow('Telepon', profile.phone!, textTheme),
                    _infoRow(
                        'Kertas', '${profile.paperWidth} mm', textTheme),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'Edit Profil',
                      icon: Icons.edit,
                      onPressed: () =>
                          _editProfile(context, profile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Printer', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.print_outlined,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Bluetooth Thermal',
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'Pairing Printer',
                      icon: Icons.bluetooth,
                      onPressed: () => _pairPrinter(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Logout',
                      style: textTheme.bodyLarge
                          ?.copyWith(color: AppColors.error)),
                  trailing: const Icon(Icons.logout,
                      color: AppColors.error),
                  onTap: () => _logout(context, ref),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Kasir Resto v1.0.0',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: tt.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Text(value, style: tt.bodyLarge),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context, RestoProfile profile) {
    showDialog(
      context: context,
      builder: (_) => _EditProfileDialog(profile: profile),
    );
  }

  void _pairPrinter(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const PrinterPairingPage()),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(authServiceProvider).signOut();
              Navigator.pop(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  final RestoProfile profile;

  const _EditProfileDialog({required this.profile});

  @override
  ConsumerState<_EditProfileDialog> createState() =>
      _EditProfileDialogState();
}

class _EditProfileDialogState
    extends ConsumerState<_EditProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addrCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _footerCtrl;
  int _paperWidth = 58;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.profile.name);
    _addrCtrl =
        TextEditingController(text: widget.profile.address ?? '');
    _phoneCtrl =
        TextEditingController(text: widget.profile.phone ?? '');
    _footerCtrl =
        TextEditingController(text: widget.profile.footerNote ?? '');
    _paperWidth = widget.profile.paperWidth;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Resto'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addrCtrl,
              decoration: const InputDecoration(labelText: 'Alamat'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration:
                  const InputDecoration(labelText: 'No. Telepon'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _footerCtrl,
              decoration: const InputDecoration(labelText: 'Footer'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Ukuran Kertas:',
                    style: AppTypography.textTheme.bodyLarge),
                const SizedBox(width: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 58, label: Text('58mm')),
                    ButtonSegment(value: 80, label: Text('80mm')),
                  ],
                  selected: {_paperWidth},
                  onSelectionChanged: (v) =>
                      setState(() => _paperWidth = v.first),
                ),
              ],
            ),
          ],
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
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final updated = widget.profile.copyWith(
        name: _nameCtrl.text.trim(),
        address: _addrCtrl.text.trim().isEmpty
            ? null
            : _addrCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        footerNote: _footerCtrl.text.trim().isEmpty
            ? null
            : _footerCtrl.text.trim(),
        paperWidth: _paperWidth,
      );
      await repo.updateProfile(updated);
      ref.invalidate(profileProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // error
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
