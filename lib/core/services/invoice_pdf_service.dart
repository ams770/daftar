import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/app_settings.dart';
import '../../features/invoices/domain/entities/invoice.dart';

class InvoicePdfService {
  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required AppSettings settings,
  }) async {
    final pdf = pw.Document();
    final isArabic = settings.language == 'AR';
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    pw.MemoryImage? logoImage;
    if (settings.logoPath != null && settings.logoPath!.isNotEmpty) {
      final logoFile = File(settings.logoPath!);
      if (await logoFile.exists()) {
        final logoBytes = await logoFile.readAsBytes();
        logoImage = pw.MemoryImage(logoBytes);
      }
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (pw.Context context) {
          return [
            _buildHeader(invoice, settings, isArabic, dateFormat, logoImage),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice, settings, isArabic),
            pw.SizedBox(height: 20),
            _buildTotals(invoice, settings, isArabic),
            pw.SizedBox(height: 40),
            _buildFooter(settings, isArabic),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    Invoice invoice,
    AppSettings settings,
    bool isArabic,
    DateFormat dateFormat,
    pw.MemoryImage? logo,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 60,
                height: 60,
                child: pw.Image(logo),
              ),
              pw.SizedBox(width: 12),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  settings.brandName,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(settings.address),
                pw.Text(settings.phone),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              '${isArabic ? 'فاتورة' : 'INVOICE'} ${invoice.type.name.toUpperCase()}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
            ),
            pw.SizedBox(height: 8),
            pw.Text('${isArabic ? 'رقم الفاتورة' : 'Invoice #'}: ${invoice.id?.toString().padLeft(4, '0') ?? 'N/A'}'),
            pw.Text('${isArabic ? 'التاريخ' : 'Date'}: ${dateFormat.format(invoice.createdAt)}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(
    Invoice invoice,
    AppSettings settings,
    bool isArabic,
  ) {
    final headers = [
      isArabic ? 'المنتج' : 'Product',
      isArabic ? 'الكود' : 'Code',
      isArabic ? 'الكمية' : 'Qty',
      isArabic ? 'سعر الوحدة' : 'Unit Price',
      isArabic ? 'الإجمالي' : 'Total',
    ];

    final data = invoice.items.map((item) {
      return [
        item.productName,
        item.productCode,
        item.qty.toString(),
        item.unitPrice.toStringAsFixed(2),
        item.lineTotal.toStringAsFixed(2),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildTotals(
    Invoice invoice,
    AppSettings settings,
    bool isArabic,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 200,
        child: pw.Column(
          children: [
            _buildTotalRow(isArabic ? 'المجموع الفرعي' : 'Subtotal', invoice.subtotal, settings.currency),
            pw.SizedBox(height: 4),
            _buildTotalRow('${isArabic ? 'الضريبة' : 'VAT'} (${invoice.vatPercent}%)', invoice.vatAmount, settings.currency),
            pw.Divider(),
            _buildTotalRow(isArabic ? 'الإجمالي' : 'Total', invoice.total, settings.currency, isBold: true),
            if (invoice.remainingAmount > 0) ...[
              pw.Divider(),
              _buildTotalRow(isArabic ? 'المدفوع' : 'Paid', invoice.paidAmount, settings.currency),
              _buildTotalRow(isArabic ? 'المتبقي' : 'Remaining', invoice.remainingAmount, settings.currency, isBold: true),
            ],
            pw.SizedBox(height: 8),
            pw.Text(
              '${isArabic ? 'طريقة الدفع' : 'Payment'}: ${invoice.paymentMethod.name.toUpperCase()}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double value, String currency, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
        pw.Text('${value.toStringAsFixed(2)} $currency', style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
      ],
    );
  }

  static pw.Widget _buildFooter(AppSettings settings, bool isArabic) {
    return pw.Center(
      child: pw.Text(
        isArabic ? 'شكراً لتعاملكم معنا' : 'Thank you for your business!',
        style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
      ),
    );
  }
}
