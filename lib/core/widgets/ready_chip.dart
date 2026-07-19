import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ReadyChip extends StatelessWidget {
  final bool ready;

  const ReadyChip({super.key, required this.ready});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ready
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        ready ? 'Ready' : 'Habis',
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: ready ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
