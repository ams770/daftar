import 'package:flutter/material.dart';
import 'core/di/injection.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/products/presentation/pages/products_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Products Printer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ProductsPage(),
    );
  }
}
