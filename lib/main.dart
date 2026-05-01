import 'package:flutter/material.dart';
import 'core/di/injection.dart' as di;
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D31FA)),
        useMaterial3: true,
        fontFamily: 'Inter', // Assuming Inter is available or fallback to default
      ),
      home: const ProductsPage(),
    );
  }
}
