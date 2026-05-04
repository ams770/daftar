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
import '../../../../core/theme/daftar_theme_extension.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_settings.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../../../core/utils/logo_helper.dart';
import '../widgets/onboarding_step.dart';
import '../widgets/onboarding_lang_form.dart';
import '../widgets/onboarding_brand_form.dart';
import '../widgets/onboarding_tax_form.dart';
import '../widgets/onboarding_bottom_bar.dart';

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
    return _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _logoFileName != null;
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
                OnboardingStep(
                  svg: 'assets/svg/onboarding-1.svg',
                  title: AppStrings.language,
                  desc: AppStrings.onboardingLangDesc,
                  content: OnboardingLangForm(
                    selectedLang: _selectedLang,
                    selectedPrintLang: _selectedPrintLang,
                    onAppLangChanged: (lang) {
                      setState(() => _selectedLang = lang);
                      context.setLocale(
                        Locale(lang == 'AR' ? 'ar' : 'en'),
                      );
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
                    onStateChanged: () => setState(() {}),
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
    );
  }
}

