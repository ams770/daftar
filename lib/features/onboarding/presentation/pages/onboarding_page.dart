import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_settings.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../../settings/presentation/widgets/settings_widgets.dart';

class OnboardingPage extends StatefulWidget {
  final AppSettings initialSettings;
  const OnboardingPage({super.key, required this.initialSettings});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _vatController;
  String? _logoPath;
  String _selectedLang = 'EN';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialSettings.brandName);
    _phoneController = TextEditingController(text: widget.initialSettings.phone);
    _addressController = TextEditingController(text: widget.initialSettings.address);
    _vatController = TextEditingController(text: widget.initialSettings.vatPercent.toString());
    _logoPath = widget.initialSettings.logoPath;
    _selectedLang = widget.initialSettings.language;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() {
    final updatedSettings = widget.initialSettings.copyWith(
      brandName: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      vatPercent: int.tryParse(_vatController.text) ?? 15,
      language: _selectedLang,
      logoPath: _logoPath,
      isOnboarded: true,
    );
    context.read<SettingsCubit>().saveSettings(updatedSettings);
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _logoPath = image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBrandStep(bento),
                  _buildTaxStep(bento),
                  _buildLangStep(bento),
                ],
              ),
            ),
            _buildBottomBar(isArabic),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, size: 48, color: AppColors.secondary),
        ),
        const Gap(AppSpacing.xl),
        Text(
          title,
          style: AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        const Gap(AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            description,
            style: AppTypography.bodyMd.copyWith(color: AppColors.greyDark),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandStep(BentoThemeExtension bento) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          _buildStepHeader(
            icon: LucideIcons.building2,
            title: AppStrings.onboardingWelcome,
            description: AppStrings.onboardingBrandDesc,
          ),
          const Gap(AppSpacing.xxl),
          GestureDetector(
            onTap: _pickLogo,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: bento.cardDecoration.boxShadow,
                    image: _logoPath != null
                        ? DecorationImage(
                            image: FileImage(File(_logoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _logoPath == null
                      ? const Icon(
                          LucideIcons.imagePlus,
                          color: AppColors.secondary,
                          size: 40,
                        )
                      : null,
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.pencil,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.xxl),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppStrings.brandName,
              prefixIcon: const Icon(LucideIcons.building),
            ),
          ),
          const Gap(AppSpacing.lg),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: AppStrings.phoneNumber,
              prefixIcon: const Icon(LucideIcons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const Gap(AppSpacing.lg),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: AppStrings.address,
              prefixIcon: const Icon(LucideIcons.mapPin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxStep(BentoThemeExtension bento) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          _buildStepHeader(
            icon: LucideIcons.percent,
            title: AppStrings.taxation,
            description: AppStrings.onboardingTaxDesc,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: bento.cardDecoration,
            child: Column(
              children: [
                Text(
                  AppStrings.vatPercentage,
                  style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold),
                ),
                const Gap(AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _vatController,
                        textAlign: TextAlign.center,
                        style: AppTypography.h1.copyWith(color: AppColors.secondary),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Text("%", style: AppTypography.h1.copyWith(color: AppColors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLangStep(BentoThemeExtension bento) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          _buildStepHeader(
            icon: LucideIcons.languages,
            title: AppStrings.language,
            description: AppStrings.onboardingLangDesc,
          ),
          const Spacer(),
          LanguageOption(
            label: AppStrings.english,
            isSelected: _selectedLang == 'EN',
            onTap: () {
              setState(() => _selectedLang = 'EN');
              context.setLocale(const Locale('en'));
            },
          ),
          const Gap(AppSpacing.lg),
          LanguageOption(
            label: AppStrings.arabic,
            isSelected: _selectedLang == 'AR',
            onTap: () {
              setState(() => _selectedLang = 'AR');
              context.setLocale(const Locale('ar'));
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _previousPage,
              child: Text(AppStrings.onboardingBack),
            ),
          const Spacer(),
          Row(
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppColors.secondary : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            ),
            child: Text(
              _currentPage == 2 ? AppStrings.onboardingFinish : AppStrings.onboardingNext,
            ),
          ),
        ],
      ),
    );
  }
}
