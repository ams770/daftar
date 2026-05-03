import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'core/constants/app_strings.dart';
import 'features/products/presentation/pages/products_page.dart';
import 'features/invoices/presentation/pages/invoices_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/settings/presentation/cubits/settings_cubit.dart';
import 'core/theme/app_colors.dart';

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
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is! SettingsLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final settings = state.settings;

        if (!settings.isOnboarded) {
          return OnboardingPage(initialSettings: settings);
        }

        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: Container(
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
                  icon: const Icon(LucideIcons.settings),
                  activeIcon: const Icon(LucideIcons.settings2),
                  label: AppStrings.settings,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
