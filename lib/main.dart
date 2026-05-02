import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_shell.dart';
import 'core/di/injection.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/products/presentation/cubits/products_cubit.dart';
import 'features/settings/presentation/cubits/settings_cubit.dart';
import 'features/invoices/presentation/cubits/invoice_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<SettingsCubit>()..loadSettings()),
        BlocProvider(create: (_) => di.sl<ProductsCubit>()..loadProducts()),
        BlocProvider(create: (_) => di.sl<InvoiceCubit>()..loadInvoices()),
      ],
      child: MaterialApp(
        title: 'Products Printer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AppShell(),
      ),
    );
  }
}
