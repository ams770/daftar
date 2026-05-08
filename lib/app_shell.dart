import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_colors.dart';
import 'features/invoices/presentation/pages/collections_page.dart';
import 'features/invoices/presentation/pages/invoices_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/products/presentation/pages/products_page.dart';
import 'features/settings/presentation/cubits/settings_cubit.dart';
import 'features/settings/presentation/pages/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ProductsPage(),
    const InvoicesPage(),
    const CollectionsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        // We always show the main structure to avoid the "blank page" feel
        return Scaffold(
          body: _buildBody(state),
          bottomNavigationBar:
              state is SettingsLoaded && state.settings.isOnboarded
              ? Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.text.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: (index) => setState(() => _selectedIndex = index),
                    backgroundColor: AppColors.white,
                    selectedItemColor: AppColors.secondary,
                    unselectedItemColor: AppColors.grey,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    type: BottomNavigationBarType.fixed,
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(LucideIcons.package),
                        activeIcon: const Icon(LucideIcons.package2),
                        label: AppStrings.inventory,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(LucideIcons.fileText),
                        activeIcon: const Icon(LucideIcons.filePlus2),
                        label: AppStrings.invoices,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(LucideIcons.wallet),
                        activeIcon: const Icon(Icons.account_balance_wallet),
                        label: AppStrings.collections,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(LucideIcons.settings),
                        activeIcon: const Icon(LucideIcons.settings2),
                        label: AppStrings.settings,
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(SettingsState state) {
    if (state is! SettingsLoaded) {
      return const ProductsPage();
    }

    final settings = state.settings;

    if (!settings.isOnboarded) {
      return OnboardingPage(initialSettings: settings);
    }

    return _pages[_selectedIndex];
  }
}
