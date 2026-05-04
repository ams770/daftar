import 'dart:io';
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
import '../../../printer/presentation/pages/printer_settings_page.dart';
import '../cubits/settings_cubit.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/settings_modals.dart';
import '../../../../core/utils/logo_helper.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings),
        elevation: 0,
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
            return _SettingsBody(settings: state.settings);
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

class _SettingsBody extends StatelessWidget {
  final AppSettings settings;
  const _SettingsBody({required this.settings});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandProfileCard(settings: settings),
          const Gap(AppSpacing.xl),

          _SectionLabel(AppStrings.language.toUpperCase()),
          _SettingsCard(
            children: [
              _Tile(
                icon: LucideIcons.languages,
                label: AppStrings.language,
                trailing: _LanguageToggle(
                  isArabic: isArabic,
                  onToggle: (ar) {
                    context.setLocale(Locale(ar ? 'ar' : 'en'));
                    final newSettings = settings.copyWith(language: ar ? 'AR' : 'EN');
                    context.read<SettingsCubit>().saveSettings(newSettings);
                  },
                ),
              ),
              const _Divider(),
              _Tile(
                icon: LucideIcons.printer,
                label: AppStrings.printingLanguage,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      settings.printingLanguage == 'AR'
                          ? AppStrings.arabic
                          : AppStrings.english,
                      style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                    ),
                    const Gap(AppSpacing.xs),
                    const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.grey),
                  ],
                ),
                onTap: () => _showPrintingLanguageModal(context),
              ),
            ],
          ),
          const Gap(AppSpacing.xl),

          _SectionLabel(AppStrings.taxation.toUpperCase()),
          _SettingsCard(
            children: [
              _Tile(
                icon: LucideIcons.percent,
                label: AppStrings.vatRate,
                trailing: Text(
                  '${settings.vatPercent}%',
                  style: AppTypography.h3.copyWith(color: AppColors.secondary),
                ),
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
              ),
              const _Divider(),
              _Tile(
                icon: LucideIcons.banknote,
                label: AppStrings.currency,
                trailing: Text(
                  settings.currency,
                  style: AppTypography.h3.copyWith(color: AppColors.secondary),
                ),
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
              ),
            ],
          ),
          const Gap(AppSpacing.xl),

          _SectionLabel("printer_setup".tr().toUpperCase()),
          _SettingsCard(
            children: [
              _Tile(
                icon: LucideIcons.bluetooth,
                label: "printer_settings".tr(),
                trailing: const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.grey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrinterSettingsPage()),
                ),
              ),
            ],
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
}

class _BrandProfileCard extends StatelessWidget {
  final AppSettings settings;
  const _BrandProfileCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    // final isArabic = context.locale.languageCode == 'ar';

    return GestureDetector(
      onTap: () => _showBrandEditModal(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.secondaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 2),
              ),
              child: settings.logoPath == null
                  ? const Icon(LucideIcons.store, color: AppColors.white, size: 30)
                  : FutureBuilder<String>(
                      future: LogoHelper.getFullPath(settings.logoPath!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && File(snapshot.data!).existsSync()) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: FileImage(File(snapshot.data!)),
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        }
                        return const Icon(LucideIcons.store, color: AppColors.white, size: 30);
                      },
                    ),
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.brandDetails,
                    style: AppTypography.label.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    settings.brandName,
                    style: AppTypography.h1.copyWith(color: AppColors.white, fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (settings.phone.isNotEmpty)
                    Text(
                      settings.phone,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(LucideIcons.pen, color: AppColors.white, size: 20),
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
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          color: AppColors.greyDark,
          fontSize: 11,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.greyLight),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.greyDark),
            const Gap(AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 50,
      color: AppColors.greyLight.withValues(alpha: 0.5),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final bool isArabic;
  final Function(bool) onToggle;
  const _LanguageToggle({required this.isArabic, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(
            label: "EN",
            isSelected: !isArabic,
            onTap: () => onToggle(false),
          ),
          _LangChip(
            label: "AR",
            isSelected: isArabic,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _LangChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.greyDark,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
