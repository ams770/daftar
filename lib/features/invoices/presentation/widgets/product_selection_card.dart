import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/daftar_theme_extension.dart';
import '../../../products/domain/entities/product.dart';

class ProductSelectionCard extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const ProductSelectionCard({
    super.key,
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final daftar = Theme.of(context).extension<DaftarThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: daftar.cardDecoration,
      child: Row(
        crossAxisAlignment: .center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: .center,
              children: [
                Text(
                  product.name,
                  style: AppTypography.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(AppSpacing.xs),
                Text(
                  product.price.toStringAsFixed(2),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (qty > 0) ...[
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    LucideIcons.circleMinus,
                    color: AppColors.danger,
                  ),
                ),
                Text('$qty', style: AppTypography.h2.copyWith(fontSize: 16)),
              ],
              IconButton(
                onPressed: onAdd,
                icon: const Icon(
                  LucideIcons.circlePlus,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
