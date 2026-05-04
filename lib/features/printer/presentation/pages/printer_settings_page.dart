import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../cubits/printer_cubit.dart';
import '../cubits/printer_state.dart';
import '../../../../core/services/printer/thermal_printer_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

class PrinterSettingsPage extends StatelessWidget {
  const PrinterSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.printerSettings),
        centerTitle: true,
      ),
      body: BlocConsumer<PrinterCubit, PrinterState>(
        listener: (context, state) {
          if (state is PrinterError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is PrinterPrintSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.printSuccess),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (state is PrinterBluetoothOff)
                SliverToBoxAdapter(child: _buildBluetoothWarning(context)),

              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: _buildMainPrinterCard(context, state),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.availableDevices,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.text,
                          fontSize: 18,
                        ),
                      ),
                      if (state is! PrinterBluetoothOff)
                        IconButton(
                          icon: const Icon(LucideIcons.refreshCcw, color: AppColors.secondary),
                          onPressed: () => context.read<PrinterCubit>().scanDevices(),
                        ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Divider(height: 32),
                ),
              ),

              _buildDeviceListSliver(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBluetoothWarning(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.danger.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(LucideIcons.bluetoothOff, color: AppColors.danger),
          const Gap(AppSpacing.md),
          Expanded(
            child: Text(
              AppStrings.bluetoothDisabled,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPrinterCard(BuildContext context, PrinterState state) {
    String? name;
    String? address;
    bool isConnected = false;
    bool isConnecting = false;

    if (state is PrinterConnected) {
      name = state.deviceName;
      address = state.address;
      isConnected = true;
    } else if (state is PrinterConnecting) {
      name = state.deviceName;
      address = state.address;
      isConnecting = true;
    } else if (state is PrinterSearching) {
      name = state.name;
      address = state.address;
      isConnecting = true;
    }

    if (name == null && address == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: (isConnected ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: (isConnected ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.printer,
                    color: isConnected ? AppColors.success : AppColors.warning,
                    size: 24,
                  ),
                ),
                const Gap(AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? AppStrings.statusConnected : AppStrings.statusConnecting,
                        style: TextStyle(
                          color: isConnected ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        name ?? AppStrings.unknownDevice,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      if (address != null)
                        Text(
                          address,
                          style: const TextStyle(color: AppColors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                  ),
              ],
            ),
            if (isConnected && state is PrinterConnected) ...[
              const Gap(AppSpacing.lg),
              const Divider(),
              const Gap(AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.paperWidth,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildWidthToggle(context, state.width ?? PrinterWidth.inch3),
                ],
              ),
            ],
            const Gap(AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showForgetDialog(context),
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: Text(AppStrings.forget),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidthToggle(BuildContext context, PrinterWidth currentWidth) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: PrinterWidth.values.map((w) {
          final isSelected = w == currentWidth;
          return GestureDetector(
            onTap: () => context.read<PrinterCubit>().connect(
              BluetoothPrinterDevice(
                name: (context.read<PrinterCubit>().state as PrinterConnected).deviceName ?? '',
                address: (context.read<PrinterCubit>().state as PrinterConnected).address ?? '',
              ),
              w,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                w == PrinterWidth.inch2
                    ? AppStrings.twoInch
                    : w == PrinterWidth.inch3
                        ? AppStrings.threeInch
                        : AppStrings.fourInch,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showForgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.forgetPrinter),
        content: Text(AppStrings.forgetPrinterConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<PrinterCubit>().disconnect();
              Navigator.pop(dialogContext);
            },
            child: Text(
              AppStrings.forget,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListSliver(BuildContext context, PrinterState state) {
    if (state is PrinterScanning) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }

    final devices = state.devices;

    if (devices.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.bluetooth, size: 48, color: AppColors.greyLight),
              const Gap(AppSpacing.md),
              Text(
                AppStrings.noDevicesFound,
                style: const TextStyle(color: AppColors.grey),
              ),
              const Gap(AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.read<PrinterCubit>().scanDevices(),
                child: Text(AppStrings.scanNow),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final device = devices[index];
          final isConnecting = state is PrinterConnecting && state.address == device.address;

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              leading: const Icon(LucideIcons.bluetooth, color: AppColors.secondary),
              title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(device.address),
              trailing: isConnecting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.chevronRight, size: 16),
              onTap: isConnecting ? null : () => _showWidthSelectionSheet(context, device),
            ),
          );
        }, childCount: devices.length),
      ),
    );
  }

  void _showWidthSelectionSheet(BuildContext context, BluetoothPrinterDevice device) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.selectPaperWidth,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const Gap(AppSpacing.sm),
              Text(
                AppStrings.selectPaperWidthDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey),
              ),
              const Gap(AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: _buildWidthOption(context, device, PrinterWidth.inch2, AppStrings.printer2Inch)),
                  const Gap(AppSpacing.md),
                  Expanded(child: _buildWidthOption(context, device, PrinterWidth.inch3, AppStrings.printer3Inch)),
                  const Gap(AppSpacing.md),
                  Expanded(child: _buildWidthOption(context, device, PrinterWidth.inch4, AppStrings.printer4Inch)),
                ],
              ),
              const Gap(AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWidthOption(BuildContext context, BluetoothPrinterDevice device, PrinterWidth width, String label) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.read<PrinterCubit>().connect(device, width);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondary, width: 2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.ruler, color: AppColors.secondary),
            const Gap(AppSpacing.sm),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
