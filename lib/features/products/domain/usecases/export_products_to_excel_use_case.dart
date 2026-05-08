import 'package:share_plus/share_plus.dart';

import '../../../../core/services/excel/excel_service.dart';
import '../repositories/product_repository.dart';

class ExportProductsToExcelUseCase {
  final ProductRepository repository;
  final ExcelService excelService;

  ExportProductsToExcelUseCase(this.repository, this.excelService);

  Future<void> call() async {
    final products = await repository.getAllProducts();
    final filePath = await excelService.exportProductsToExcel(products);

    await Share.shareXFiles([XFile(filePath)], text: 'Products Export');
  }
}
