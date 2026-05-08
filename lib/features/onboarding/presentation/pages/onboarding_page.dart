import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/logo_helper.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../widgets/onboarding_bottom_bar.dart';
import '../widgets/onboarding_brand_form.dart';
import '../widgets/onboarding_lang_form.dart';
import '../widgets/onboarding_step.dart';
import '../widgets/onboarding_tax_form.dart';

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
  bool _isBrandSkipped = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialSettings.brandName,
    );
    _phoneController = TextEditingController(
      text: widget.initialSettings.phone,
    );
    _addressController = TextEditingController(
      text: widget.initialSettings.address,
    );
    _vatController = TextEditingController(
      text: widget.initialSettings.vatPercent.toString(),
    );
    _currencyController = TextEditingController(
      text: widget.initialSettings.currency,
    );

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
    final focused =
        _nameFocus.hasFocus ||
        _phoneFocus.hasFocus ||
        _addressFocus.hasFocus ||
        _vatFocus.hasFocus ||
        _currencyFocus.hasFocus;
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
    if (_isBrandSkipped) return true;
    return _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _logoFileName != null;
  }

  void _skipAll() {
    setState(() {
      if (_nameController.text.isEmpty) {
        _nameController.text = 'app_name'.tr();
      }
      if (_phoneController.text.isEmpty) {
        _phoneController.text = '';
      }
      if (_addressController.text.isEmpty) {
        _addressController.text = '';
      }
      if (_vatController.text.isEmpty) {
        _vatController.text = '15';
      }
      if (_currencyController.text.isEmpty) {
        _currencyController.text = widget.initialSettings.currency;
      }
      _isBrandSkipped = true;
    });
    _finish();
  }

  bool get _isPage2Valid =>
      _vatController.text.isNotEmpty && _currencyController.text.isNotEmpty;

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
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
                    OnboardingStep(
                      svg: 'assets/svg/onboarding-1.svg',
                      title: AppStrings.language,
                      desc: AppStrings.onboardingLangDesc,
                      content: OnboardingLangForm(
                        selectedLang: _selectedLang,
                        selectedPrintLang: _selectedPrintLang,
                        onAppLangChanged: (lang) {
                          setState(() => _selectedLang = lang);
                          context.setLocale(Locale(lang == 'AR' ? 'ar' : 'en'));
                        },
                        onPrintLangChanged: (lang) {
                          setState(() => _selectedPrintLang = lang);
                        },
                      ),
                    ),
                    OnboardingStep(
                      svg: 'assets/svg/onboarding-2.svg',
                      title: AppStrings.onboardingWelcome,
                      desc: AppStrings.onboardingBrandDesc,
                      content: OnboardingBrandForm(
                        nameController: _nameController,
                        phoneController: _phoneController,
                        addressController: _addressController,
                        nameFocus: _nameFocus,
                        phoneFocus: _phoneFocus,
                        addressFocus: _addressFocus,
                        logoPath: _logoPath,
                        logoFileName: _logoFileName,
                        onPickLogo: _pickLogo,
                        onStateChanged: () {
                          setState(() {
                            _isBrandSkipped = false;
                          });
                        },
                        onNext: () {
                          if (_isPage1Valid) _nextPage();
                        },
                      ),
                    ),
                    OnboardingStep(
                      svg: 'assets/svg/onboarding-3.svg',
                      title: AppStrings.taxation,
                      desc: AppStrings.onboardingTaxDesc,
                      content: OnboardingTaxForm(
                        vatController: _vatController,
                        currencyController: _currencyController,
                        vatFocus: _vatFocus,
                        currencyFocus: _currencyFocus,
                        onStateChanged: () => setState(() {}),
                        onNext: () {
                          if (_isPage2Valid) _nextPage();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isFieldFocused ? 0 : null,
                child: _isFieldFocused
                    ? const SizedBox.shrink()
                    : OnboardingBottomBar(
                        currentPage: _currentPage,
                        isCurrentPageValid: _isCurrentPageValid,
                        onPrevious: _previousPage,
                        onNext: _nextPage,
                      ),
              ),
            ],
          ),
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: MediaQuery.of(context).padding.top + 16,
            end: 16,
            child: AnimatedOpacity(
              opacity: _isFieldFocused ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: _isFieldFocused,
                child: TextButton(
                  onPressed: _skipAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.skip,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        context.locale.languageCode == 'ar'
                            ? LucideIcons.chevronLeft
                            : LucideIcons.chevronRight,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
