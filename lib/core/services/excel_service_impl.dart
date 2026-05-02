import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/products/domain/entities/excel_product.dart';
import '../../features/products/domain/entities/product.dart';
import 'excel_service.dart';

class ExcelServiceImpl implements ExcelService {
  @override
  Future<List<ExcelProduct>> readProductsFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    // Use compute to run the heavy parsing logic in a separate isolate
    return await compute(_parseExcel, bytes);
  }

  static List<ExcelProduct> _parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final List<ExcelProduct> products = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table]!;
      // Skip header row
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        final name = row[0]?.value?.toString() ?? '';
        final code = row[1]?.value?.toString() ?? '';
        final price = double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0.0;

        if (name.isNotEmpty && code.isNotEmpty) {
          products.add(ExcelProduct(
            name: name,
            code: code,
            price: price,
          ));
        }
      }
    }
    return products;
  }

  @override
  Future<String> exportProductsToExcel(List<Product> products) async {
    final excel = Excel.createExcel();
    final sheet = excel['Products'];
    
    // Add Header
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Code'),
      TextCellValue('Price'),
    ]);

    // Add Data
    for (final product in products) {
      sheet.appendRow([
        TextCellValue(product.name),
        TextCellValue(product.code),
        DoubleCellValue(product.price),
      ]);
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/products_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final fileBytes = excel.save();
    
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }

    return filePath;
  }
}
