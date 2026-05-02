import 'dart:io';
import '../../features/products/domain/entities/excel_product.dart';
import '../../features/products/domain/entities/product.dart';

abstract class ExcelService {
  Future<List<ExcelProduct>> readProductsFromExcel(File file);
  Future<String> exportProductsToExcel(List<Product> products);
}
