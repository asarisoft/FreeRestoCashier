import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../auth/auth_controller.dart';
import '../onboarding/onboarding_page.dart';
import '../pos/pos_page.dart';
import '../products/product_list_page.dart';
import '../reports/report_page.dart';
import '../expenses/expense_list_page.dart';
import '../settings/settings_page.dart';
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) return const OnboardingPage();
        return const _MainShell();
      },
    );
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _tab = 0;

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
          border: isSelected
              ? const Border(left: BorderSide(color: AppColors.primary, width: 4))
              : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      PosPage(),
      ProductListPage(),
      ReportPage(),
      ExpenseListPage(),
      SettingsPage(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                // Sidebar
                Container(
                  width: 250,
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: AppColors.primary, size: 32),
                            const SizedBox(width: 12),
                            Text('POSPRO', style: AppTypography.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text('MAIN MENU', style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
                      ),
                      _buildSidebarItem(0, Icons.point_of_sale, 'Order'),
                      _buildSidebarItem(2, Icons.bar_chart, 'Statistics'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8).copyWith(top: 16),
                        child: Text('MANAGEMENT', style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
                      ),
                      _buildSidebarItem(1, Icons.inventory_2, 'Products'),
                      _buildSidebarItem(3, Icons.receipt_long, 'Expenses'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8).copyWith(top: 16),
                        child: Text('SUPPORT', style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
                      ),
                      _buildSidebarItem(4, Icons.settings, 'Settings'),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: pages,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _tab,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withValues(alpha: 0.2),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary),
                label: 'Kasir',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
                label: 'Produk',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
                label: 'Laporan',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
                label: 'Biaya',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: AppColors.primary),
                label: 'Setting',
              ),
            ],
          ),
        );
      },
    );
  }
}
