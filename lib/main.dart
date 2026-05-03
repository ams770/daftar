import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app_shell.dart';
import 'core/di/injection.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/products/presentation/cubits/products_cubit.dart';
import 'features/settings/presentation/cubits/settings_cubit.dart';
import 'features/invoices/presentation/cubits/invoice_cubit.dart';
import 'features/invoices/presentation/cubits/add_invoice_cubit.dart';
import 'features/invoices/presentation/cubits/money_collection_cubit.dart';
import 'features/printer/presentation/cubits/printer_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await di.init();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<SettingsCubit>()..loadSettings()),
        BlocProvider(create: (_) => di.sl<InvoiceCubit>()..loadInvoices()),
        BlocProvider(create: (_) => di.sl<AddInvoiceCubit>()),
        BlocProvider(create: (_) => di.sl<MoneyCollectionCubit>()),
        BlocProvider(create: (_) => di.sl<PrinterCubit>()),
      ],
      child: MaterialApp(
        title: 'Products Printer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const AppShell(),
      ),
    );
  }
}
