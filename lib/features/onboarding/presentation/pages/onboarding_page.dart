import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_settings.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../../../core/utils/logo_helper.dart';

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
  late TextEditingController _currencyController;
  
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _vatFocus = FocusNode();
  final FocusNode _currencyFocus = FocusNode();

  String? _logoPath;
  String? _logoFileName;
  String _selectedLang = 'EN';
  String _selectedPrintLang = 'EN';
  
  bool _isFieldFocused = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialSettings.brandName);
    _phoneController = TextEditingController(text: widget.initialSettings.phone);
    _addressController = TextEditingController(text: widget.initialSettings.address);
    _vatController = TextEditingController(text: widget.initialSettings.vatPercent.toString());
    _currencyController = TextEditingController(text: widget.initialSettings.currency);
    
    _logoFileName = widget.initialSettings.logoPath;
    if (_logoFileName != null) {
      LogoHelper.getFullPath(_logoFileName!).then((path) {
        if (mounted) setState(() => _logoPath = path);
      });
    }
    
    _selectedLang = widget.initialSettings.language;
    _selectedPrintLang = widget.initialSettings.printingLanguage;

    _nameFocus.addListener(_onFocusChange);
    _phoneFocus.addListener(_onFocusChange);
    _addressFocus.addListener(_onFocusChange);
    _vatFocus.addListener(_onFocusChange);
    _currencyFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final focused = _nameFocus.hasFocus || _phoneFocus.hasFocus || _addressFocus.hasFocus || _vatFocus.hasFocus || _currencyFocus.hasFocus;
    if (focused != _isFieldFocused) {
      setState(() => _isFieldFocused = focused);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vatController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _vatFocus.dispose();
    _currencyFocus.dispose();
    super.dispose();
  }

  bool get _isPage1Valid {
    return _nameController.text.isNotEmpty && 
           _phoneController.text.isNotEmpty && 
           _addressController.text.isNotEmpty && 
           _logoFileName != null;
  }

  bool get _isPage2Valid => _vatController.text.isNotEmpty && _currencyController.text.isNotEmpty;

  bool get _isCurrentPageValid {
    if (_currentPage == 0) return true; // Language
    if (_currentPage == 1) return _isPage1Valid; // Brand
    if (_currentPage == 2) return _isPage2Valid; // Tax
    return true;
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      );
    } else {
      _finish();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _finish() {
    final updatedSettings = widget.initialSettings.copyWith(
      brandName: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      vatPercent: int.tryParse(_vatController.text) ?? 15,
      currency: _currencyController.text,
      language: _selectedLang,
      printingLanguage: _selectedPrintLang,
      logoPath: _logoFileName,
      isOnboarded: true,
    );
    context.read<SettingsCubit>().saveSettings(updatedSettings);
  }

  Future<void> _pickLogo() async {
    final String? fileName = await LogoHelper.pickAndSaveLogo();
    if (fileName != null) {
      final fullPath = await LogoHelper.getFullPath(fileName);
      setState(() {
        _logoFileName = fileName;
        _logoPath = fullPath;
      });
      // Auto advance if valid
      if (_isPage1Valid && _currentPage == 1) {
        _nextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                FocusScope.of(context).unfocus();
                setState(() => _currentPage = index);
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep(
                  bento: bento,
                  svg: 'assets/svg/onboarding-1.svg',
                  title: AppStrings.language,
                  desc: AppStrings.onboardingLangDesc,
                  content: _buildLangForm(bento),
                ),
                _buildStep(
                  bento: bento,
                  svg: 'assets/svg/onboarding-2.svg',
                  title: AppStrings.onboardingWelcome,
                  desc: AppStrings.onboardingBrandDesc,
                  content: _buildBrandForm(bento),
                ),
                _buildStep(
                  bento: bento,
                  svg: 'assets/svg/onboarding-3.svg',
                  title: AppStrings.taxation,
                  desc: AppStrings.onboardingTaxDesc,
                  content: _buildTaxForm(bento),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isFieldFocused ? 0 : null,
            child: _isFieldFocused ? const SizedBox.shrink() : _buildBottomBar(bento),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required BentoThemeExtension bento,
    required String svg,
    required String title,
    required String desc,
    required Widget content,
  }) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 60, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              children: [
                SvgPicture.asset(svg, height: 200),
                const Gap(AppSpacing.xl),
                Text(title, style: AppTypography.h1, textAlign: TextAlign.center),
                const Gap(AppSpacing.sm),
                Text(
                  desc,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.greyDark),
                  textAlign: TextAlign.center,
                ),
                const Gap(AppSpacing.xxl),
                content,
                const Gap(100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandForm(BentoThemeExtension bento) {
    return Column(
      children: [
        _buildLogoPicker(bento),
        const Gap(AppSpacing.xxl),
        _buildTextField(
          controller: _nameController,
          focusNode: _nameFocus,
          label: AppStrings.brandName,
          icon: LucideIcons.building,
          action: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocus),
          onChanged: (_) => setState(() {}),
        ),
        const Gap(AppSpacing.lg),
        _buildTextField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          label: AppStrings.phoneNumber,
          icon: LucideIcons.phone,
          action: TextInputAction.next,
          keyboardType: TextInputType.phone,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_addressFocus),
          onChanged: (_) => setState(() {}),
        ),
        const Gap(AppSpacing.lg),
        _buildTextField(
          controller: _addressController,
          focusNode: _addressFocus,
          label: AppStrings.address,
          icon: LucideIcons.mapPin,
          action: TextInputAction.done,
          onSubmitted: (_) {
            FocusScope.of(context).unfocus();
            if (_isPage1Valid) _nextPage();
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildLogoPicker(BentoThemeExtension bento) {
    return GestureDetector(
      onTap: _pickLogo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: _logoFileName != null ? AppColors.secondary : AppColors.greyLight,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              image: _logoPath != null && File(_logoPath!).existsSync()
                  ? DecorationImage(image: FileImage(File(_logoPath!)), fit: BoxFit.cover)
                  : null,
            ),
            child: _logoPath == null
                ? const Icon(LucideIcons.camera, color: AppColors.grey, size: 32)
                : null,
          ),
          if (_logoFileName != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                child: const Icon(LucideIcons.check, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaxForm(BentoThemeExtension bento) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: bento.cardDecoration,
      child: Column(
        children: [
          Text(AppStrings.vatPercentage, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold)),
          const Gap(AppSpacing.lg),
          _buildTextField(
            controller: _vatController,
            focusNode: _vatFocus,
            label: "%",
            icon: LucideIcons.percent,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            action: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => FocusScope.of(context).requestFocus(_currencyFocus),
          ),
          const Gap(AppSpacing.xl),
          Text(AppStrings.currency, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold)),
          const Gap(AppSpacing.lg),
          _buildTextField(
            controller: _currencyController,
            focusNode: _currencyFocus,
            label: AppStrings.currencyCode,
            icon: LucideIcons.coins,
            textAlign: TextAlign.center,
            action: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
              if (_isPage2Valid) _nextPage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLangForm(BentoThemeExtension bento) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionTitle(AppStrings.appLanguage, AppStrings.appLanguageDesc),
        const Gap(AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildSelectionCard(
                label: AppStrings.english,
                isSelected: _selectedLang == 'EN',
                onTap: () {
                  setState(() => _selectedLang = 'EN');
                  context.setLocale(const Locale('en'));
                },
              ),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: _buildSelectionCard(
                label: AppStrings.arabic,
                isSelected: _selectedLang == 'AR',
                onTap: () {
                  setState(() => _selectedLang = 'AR');
                  context.setLocale(const Locale('ar'));
                },
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.xl),
        _buildSelectionTitle(AppStrings.printingLanguage, AppStrings.printingLanguageDesc),
        const Gap(AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildSelectionCard(
                label: AppStrings.english,
                isSelected: _selectedPrintLang == 'EN',
                onTap: () => setState(() => _selectedPrintLang = 'EN'),
              ),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: _buildSelectionCard(
                label: AppStrings.arabic,
                isSelected: _selectedPrintLang == 'AR',
                onTap: () => setState(() => _selectedPrintLang = 'AR'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionTitle(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h3),
        Text(desc, style: AppTypography.bodySm.copyWith(color: AppColors.greyDark)),
      ],
    );
  }

  Widget _buildSelectionCard({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withValues(alpha: 0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.greyLight,
            width: 2,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyLg.copyWith(
              color: isSelected ? AppColors.secondary : AppColors.text,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? action,
    TextAlign textAlign = TextAlign.start,
    void Function(String)? onSubmitted,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: action,
      textAlign: textAlign,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.white,
        floatingLabelStyle: const TextStyle(color: AppColors.secondary),
        prefixIconColor: WidgetStateColor.resolveWith((states) => 
          states.contains(WidgetState.focused) ? AppColors.secondary : AppColors.grey
        ),
      ),
    );
  }

  Widget _buildBottomBar(BentoThemeExtension bento) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentPage > 0)
              IconButton(
                onPressed: _previousPage,
                icon: const Icon(LucideIcons.arrowLeft),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  gradient: _isCurrentPageValid 
                      ? const LinearGradient(colors: AppColors.secondaryGradient)
                      : null,
                  color: _isCurrentPageValid ? null : AppColors.greyLight,
                  boxShadow: _isCurrentPageValid ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ] : [],
                ),
                child: ElevatedButton(
                  onPressed: _isCurrentPageValid ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.greyDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  child: Text(
                    _currentPage == 2 ? AppStrings.onboardingFinish : AppStrings.onboardingNext,
                    style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold, color: _isCurrentPageValid ? Colors.white : AppColors.greyDark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
