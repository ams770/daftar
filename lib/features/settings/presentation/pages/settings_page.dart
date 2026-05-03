import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/models/app_settings.dart';
import '../../../../core/constants/app_strings.dart';
import '../cubits/settings_cubit.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/settings_modals.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsInitial) {
            context.read<SettingsCubit>().loadSettings();
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SettingsLoaded) {
            return _SettingsContent(settings: state.settings);
          }
          if (state is SettingsError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.danger),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final AppSettings settings;
  const _SettingsContent({required this.settings});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSection(
            title: AppStrings.brandDetails,
            onTap: () => _showBrandEditModal(context),
            child: Row(
              children: [
                LogoPreview(path: settings.logoPath),
                const Gap(AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(settings.brandName, style: AppTypography.h2),
                      if (settings.phone.isNotEmpty) ...[
                        const Gap(AppSpacing.xs),
                        Text(
                          settings.phone,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                      if (settings.address.isNotEmpty) ...[
                        const Gap(AppSpacing.xs),
                        Text(
                          settings.address,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.xl),
          SettingsSection(
            title: AppStrings.taxation,
            onTap: () => _showValueEditModal(
              context,
              title: AppStrings.editVat,
              label: AppStrings.vatPercentage,
              initialValue: settings.vatPercent.toString(),
              icon: LucideIcons.percent,
              keyboardType: TextInputType.number,
              onSave: (val) {
                final newSettings = settings.copyWith(
                  vatPercent: int.tryParse(val) ?? 15,
                );
                context.read<SettingsCubit>().saveSettings(newSettings);
              },
            ),
            child: SettingRow(
              icon: LucideIcons.percent,
              label: AppStrings.vatRate,
              value: '${settings.vatPercent}%',
            ),
          ),
          const Gap(AppSpacing.xl),
          SettingsSection(
            title: AppStrings.currency,
            onTap: () => _showValueEditModal(
              context,
              title: AppStrings.editCurrency,
              label: AppStrings.currencyCode,
              initialValue: settings.currency,
              icon: LucideIcons.banknote,
              onSave: (val) {
                final newSettings = settings.copyWith(currency: val);
                context.read<SettingsCubit>().saveSettings(newSettings);
              },
            ),
            child: SettingRow(
              icon: LucideIcons.banknote,
              label: AppStrings.defaultCurrency,
              value: settings.currency,
            ),
          ),
          const Gap(AppSpacing.xl),
          SettingsSection(
            title: AppStrings.language,
            onTap: () => _showLanguageModal(context),
            child: SettingRow(
              icon: LucideIcons.languages,
              label: AppStrings.selectLanguage,
              value: context.locale.languageCode == 'ar'
                  ? AppStrings.arabic
                  : AppStrings.english,
            ),
          ),
          const Gap(AppSpacing.xl),
          SettingsSection(
            title: AppStrings.printingLanguage,
            onTap: () => _showPrintingLanguageModal(context),
            child: SettingRow(
              icon: LucideIcons.printer,
              label: AppStrings.selectLanguage,
              value: settings.printingLanguage == 'AR'
                  ? AppStrings.arabic
                  : AppStrings.english,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintingLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.printingLanguage, style: AppTypography.h2),
            const Gap(AppSpacing.lg),
            LanguageOption(
              label: AppStrings.english,
              isSelected: settings.printingLanguage == 'EN',
              onTap: () {
                context.read<SettingsCubit>().updatePrintingLanguage('EN');
                Navigator.pop(context);
              },
            ),
            const Gap(AppSpacing.md),
            LanguageOption(
              label: AppStrings.arabic,
              isSelected: settings.printingLanguage == 'AR',
              onTap: () {
                context.read<SettingsCubit>().updatePrintingLanguage('AR');
                Navigator.pop(context);
              },
            ),
            const Gap(AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showBrandEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsCubit>(),
        child: BrandEditModal(settings: settings),
      ),
    );
  }

  void _showValueEditModal(
    BuildContext context, {
    required String title,
    required String label,
    required String initialValue,
    required IconData icon,
    required Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SimpleEditModal(
        title: title,
        label: label,
        initialValue: initialValue,
        icon: icon,
        onSave: onSave,
        keyboardType: keyboardType,
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.selectLanguage, style: AppTypography.h2),
            const Gap(AppSpacing.lg),
            LanguageOption(
              label: AppStrings.english,
              isSelected: context.locale.languageCode == 'en',
              onTap: () {
                context.setLocale(const Locale('en'));
                final newSettings = settings.copyWith(language: 'EN');
                context.read<SettingsCubit>().saveSettings(newSettings);
                Navigator.pop(context);
              },
            ),
            const Gap(AppSpacing.md),
            LanguageOption(
              label: AppStrings.arabic,
              isSelected: context.locale.languageCode == 'ar',
              onTap: () {
                context.setLocale(const Locale('ar'));
                final newSettings = settings.copyWith(language: 'AR');
                context.read<SettingsCubit>().saveSettings(newSettings);
                Navigator.pop(context);
              },
            ),
            const Gap(AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
