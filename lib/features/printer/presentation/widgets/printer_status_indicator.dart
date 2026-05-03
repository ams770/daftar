import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../cubits/printer_cubit.dart';
import '../cubits/printer_state.dart';
import '../pages/printer_settings_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class PrinterStatusIndicator extends StatelessWidget {
  const PrinterStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrinterCubit, PrinterState>(
      builder: (context, state) {
        final isConnected = state is PrinterConnected || state is PrinterPrinting || state is PrinterPrintSuccess;
        final isConnecting = state is PrinterConnecting || state is PrinterSearching;
        final isError = state is PrinterError || state is PrinterBluetoothOff;

        Color color = AppColors.grey;
        if (isConnected) color = AppColors.success;
        if (isConnecting) color = AppColors.warning;
        if (isError) color = AppColors.danger;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrinterSettingsPage()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isConnecting)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Icon(LucideIcons.printer, size: 14, color: color),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
