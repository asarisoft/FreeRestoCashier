import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Kasir Resto',
                style: textTheme.displayMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Catat penjualan, kelola produk,\ndan cetak struk dengan mudah',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                label: 'Masuk dengan Google',
                icon: Icons.login,
                loading: _loading,
                onPressed: _loading ? null : () => _signIn(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final auth = ref.read(authServiceProvider);
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal masuk: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
