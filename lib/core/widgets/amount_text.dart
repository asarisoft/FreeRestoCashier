import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_typography.dart';

class AmountText extends StatelessWidget {
  final int amount;
  final TextStyle? style;
  final bool showZero;

  static final _format = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (amount == 0 && !showZero) return const SizedBox.shrink();
    return Text(
      _format.format(amount),
      style: (style ?? AppTypography.textTheme.bodyLarge)
          ?.apply(fontFeatures: [const FontFeature.tabularFigures()]),
    );
  }
}

class AmountTotal extends StatelessWidget {
  final int amount;

  const AmountTotal({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Text(
      AmountText._format.format(amount),
      style: AppTypography.textTheme.displayMedium
          ?.apply(fontFeatures: [const FontFeature.tabularFigures()]),
    );
  }
}
