import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/app_settings.dart';
import '../../features/invoices/domain/entities/invoice.dart';
import '../../features/invoices/domain/entities/money_collection.dart';
import 'package:flutter/services.dart';

class InvoicePdfService {
  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required AppSettings settings,
  }) async {
    final pdf = pw.Document();
    final isArabic = settings.printingLanguage == 'AR';
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Load fonts
    final fontData = await rootBundle.load('assets/fonts/Alex/Alex-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Alex/Alex-Bold.ttf');
    final alexFont = pw.Font.ttf(fontData);
    final alexFontBold = pw.Font.ttf(fontBoldData);

    final baseStyle = pw.TextStyle(font: alexFont, fontSize: 10);
    final boldStyle = pw.TextStyle(font: alexFontBold, fontWeight: pw.FontWeight.bold, fontSize: 10);

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
        theme: pw.ThemeData.withFont(
          base: alexFont,
          bold: alexFontBold,
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(invoice, settings, isArabic, dateFormat, logoImage, boldStyle, baseStyle),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice, settings, isArabic, boldStyle, baseStyle),
            pw.SizedBox(height: 20),
            _buildTotals(invoice, settings, isArabic, boldStyle, baseStyle),
            pw.SizedBox(height: 40),
            _buildFooter(settings, isArabic, baseStyle),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateCollectionPdf({
    required MoneyCollection collection,
    required AppSettings settings,
  }) async {
    final pdf = pw.Document();
    final isArabic = settings.printingLanguage == 'AR';
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Load fonts
    final fontData = await rootBundle.load('assets/fonts/Alex/Alex-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Alex/Alex-Bold.ttf');
    final alexFont = pw.Font.ttf(fontData);
    final alexFontBold = pw.Font.ttf(fontBoldData);

    final baseStyle = pw.TextStyle(font: alexFont, fontSize: 10);
    final boldStyle = pw.TextStyle(font: alexFontBold, fontWeight: pw.FontWeight.bold, fontSize: 10);

    pw.MemoryImage? logoImage;
    if (settings.logoPath != null && settings.logoPath!.isNotEmpty) {
      final logoFile = File(settings.logoPath!);
      if (await logoFile.exists()) {
        final logoBytes = await logoFile.readAsBytes();
        logoImage = pw.MemoryImage(logoBytes);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(
          base: alexFont,
          bold: alexFontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildCollectionHeader(collection, settings, isArabic, dateFormat, logoImage, boldStyle, baseStyle),
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    _buildSummaryRow(isArabic ? 'المبلغ المحصل' : 'Collected Amount', collection.amount, settings.currency, boldStyle, baseStyle, isBold: true, fontSize: 18),
                    pw.Divider(color: PdfColors.grey400),
                    _buildSummaryRow(isArabic ? 'المتبقي قبل' : 'Remaining Before', collection.remainingBefore, settings.currency, boldStyle, baseStyle),
                    _buildSummaryRow(isArabic ? 'المتبقي بعد' : 'Remaining After', collection.remainingAfter, settings.currency, boldStyle, baseStyle, isBold: true),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                '${isArabic ? 'تفاصيل الفاتورة' : 'Invoice Details'}: #${collection.invoiceId}',
                style: boldStyle.copyWith(fontSize: 12),
              ),
              if (collection.clientName != null)
                pw.Text('${isArabic ? 'العميل' : 'Client'}: ${collection.clientName}', style: baseStyle),
              pw.Spacer(),
              _buildFooter(settings, isArabic, baseStyle),
            ],
          );
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
    pw.TextStyle boldStyle,
    pw.TextStyle baseStyle,
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
                  style: boldStyle.copyWith(fontSize: 18),
                ),
                pw.SizedBox(height: 4),
                pw.Text(settings.address, style: baseStyle),
                pw.Text(settings.phone, style: baseStyle),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              '${isArabic ? 'فاتورة' : 'INVOICE'} ${invoice.type.name.toUpperCase()}',
              style: boldStyle.copyWith(fontSize: 16, color: PdfColors.blue700),
            ),
            pw.SizedBox(height: 8),
            pw.Text('${isArabic ? 'رقم الفاتورة' : 'Invoice #'}: ${invoice.id?.toString().padLeft(4, '0') ?? 'N/A'}', style: baseStyle),
            pw.Text('${isArabic ? 'التاريخ' : 'Date'}: ${dateFormat.format(invoice.createdAt)}', style: baseStyle),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(
    Invoice invoice,
    AppSettings settings,
    bool isArabic,
    pw.TextStyle boldStyle,
    pw.TextStyle baseStyle,
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
      headerStyle: boldStyle.copyWith(color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellStyle: baseStyle,
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
    pw.TextStyle boldStyle,
    pw.TextStyle baseStyle,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 200,
        child: pw.Column(
          children: [
            _buildTotalRow(isArabic ? 'المجموع الفرعي' : 'Subtotal', invoice.subtotal, settings.currency, baseStyle),
            pw.SizedBox(height: 4),
            _buildTotalRow('${isArabic ? 'الضريبة' : 'VAT'} (${invoice.vatPercent}%)', invoice.vatAmount, settings.currency, baseStyle),
            pw.Divider(),
            _buildTotalRow(isArabic ? 'الإجمالي' : 'Total', invoice.total, settings.currency, boldStyle, isBold: true),
            if (invoice.remainingAmount > 0) ...[
              pw.Divider(),
              _buildTotalRow(isArabic ? 'المدفوع' : 'Paid', invoice.paidAmount, settings.currency, baseStyle),
              _buildTotalRow(isArabic ? 'المتبقي' : 'Remaining', invoice.remainingAmount, settings.currency, boldStyle, isBold: true),
            ],
            pw.SizedBox(height: 8),
            pw.Text(
              '${isArabic ? 'طريقة الدفع' : 'Payment'}: ${invoice.paymentMethod.name.toUpperCase()}',
              style: baseStyle.copyWith(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double value, String currency, pw.TextStyle style, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text('${value.toStringAsFixed(2)} $currency', style: style),
      ],
    );
  }

  static pw.Widget _buildFooter(AppSettings settings, bool isArabic, pw.TextStyle baseStyle) {
    return pw.Center(
      child: pw.Text(
        isArabic ? 'شكراً لتعاملكم معنا' : 'Thank you for your business!',
        style: baseStyle.copyWith(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
      ),
    );
  }

  static pw.Widget _buildCollectionHeader(
    MoneyCollection collection,
    AppSettings settings,
    bool isArabic,
    DateFormat dateFormat,
    pw.MemoryImage? logo,
    pw.TextStyle boldStyle,
    pw.TextStyle baseStyle,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) pw.Container(height: 50, width: 50, child: pw.Image(logo)),
            pw.Text(settings.brandName, style: boldStyle.copyWith(fontSize: 14)),
            pw.Text(settings.phone, style: baseStyle.copyWith(fontSize: 8)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              isArabic ? 'سند قبض' : 'RECEIPT',
              style: boldStyle.copyWith(fontSize: 18, color: PdfColors.blue700),
            ),
            pw.Text('${isArabic ? 'التاريخ' : 'Date'}: ${dateFormat.format(collection.createdAt)}', style: baseStyle.copyWith(fontSize: 8)),
            pw.Text('${isArabic ? 'الرقم' : 'No'}: #${collection.id?.toString().padLeft(4, '0') ?? 'N/A'}', style: baseStyle.copyWith(fontSize: 8)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(String label, double value, String currency, pw.TextStyle boldStyle, pw.TextStyle baseStyle, {bool isBold = false, double fontSize = 10}) {
    final style = isBold ? boldStyle.copyWith(fontSize: fontSize) : baseStyle.copyWith(fontSize: fontSize);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('${value.toStringAsFixed(2)} $currency', style: style),
        ],
      ),
    );
  }
}
