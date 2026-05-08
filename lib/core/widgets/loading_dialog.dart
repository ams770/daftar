import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:products_printer/core/theme/app_colors.dart';
import 'package:products_printer/core/theme/app_spacing.dart';
import 'package:products_printer/core/theme/app_typography.dart';

class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({super.key, required this.message});

  static void show(BuildContext context, {required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/loading-data.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const Gap(AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
