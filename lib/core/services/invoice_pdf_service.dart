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
    final fontData = await rootBundle.load(
      'assets/fonts/Alex/Alex-Regular.ttf',
    );
    final fontBoldData = await rootBundle.load(
      'assets/fonts/Alex/Alex-Bold.ttf',
    );
    final alexFont = pw.Font.ttf(fontData);
    final alexFontBold = pw.Font.ttf(fontBoldData);

    final baseStyle = pw.TextStyle(font: alexFont, fontSize: 8);
    final boldStyle = pw.TextStyle(
      font: alexFontBold,
      fontWeight: pw.FontWeight.bold,
      fontSize: 8,
    );

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
        pageFormat: PdfPageFormat.roll80,
        margin: pw.EdgeInsets.zero,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: alexFont, bold: alexFontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildUnifiedHeader(
                title:
                    '${isArabic ? 'فاتورة' : 'INVOICE'} ${invoice.type.label(isArabic)}',
                id: invoice.id?.toString().padLeft(4, '0') ?? 'N/A',
                date: dateFormat.format(invoice.createdAt),
                settings: settings,
                isArabic: isArabic,
                logo: logoImage,
                boldStyle: boldStyle,
                baseStyle: baseStyle,
              ),
              _buildItemsTable(
                invoice,
                settings,
                isArabic,
                boldStyle,
                baseStyle,
              ),
              _buildTotals(invoice, settings, isArabic, boldStyle, baseStyle),
              // _buildFooter(settings, isArabic, baseStyle),
              pw.SizedBox(height: 30),
            ],
          );
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
    final fontData = await rootBundle.load(
      'assets/fonts/Alex/Alex-Regular.ttf',
    );
    final fontBoldData = await rootBundle.load(
      'assets/fonts/Alex/Alex-Bold.ttf',
    );
    final alexFont = pw.Font.ttf(fontData);
    final alexFontBold = pw.Font.ttf(fontBoldData);

    final baseStyle = pw.TextStyle(font: alexFont, fontSize: 8);
    final boldStyle = pw.TextStyle(
      font: alexFontBold,
      fontWeight: pw.FontWeight.bold,
      fontSize: 8,
    );

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
        pageFormat: PdfPageFormat.roll80.copyWith(),
        margin: pw.EdgeInsets.zero,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: alexFont, bold: alexFontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildUnifiedHeader(
                title: isArabic ? 'سند تحصيل' : 'RECEIPT',
                id: collection.id?.toString().padLeft(4, '0') ?? 'N/A',
                date: dateFormat.format(collection.createdAt),
                settings: settings,
                isArabic: isArabic,
                logo: logoImage,
                boldStyle: boldStyle,
                baseStyle: baseStyle,
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  children: [
                    _buildSummaryRow(
                      isArabic ? 'المبلغ المحصل' : 'Collected Amount',
                      collection.amount,
                      settings.currency,
                      boldStyle,
                      baseStyle,
                      isBold: true,
                      fontSize: 11,
                    ),
                    pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                    _buildSummaryRow(
                      isArabic ? 'المتبقي قبل' : 'Remaining Before',
                      collection.remainingBefore,
                      settings.currency,
                      boldStyle,
                      baseStyle,
                      fontSize: 10,
                    ),
                    _buildSummaryRow(
                      isArabic ? 'المتبقي بعد' : 'Remaining After',
                      collection.remainingAfter,
                      settings.currency,
                      boldStyle,
                      baseStyle,
                      fontSize: 10,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  '${isArabic ? 'رقم الفاتورة' : 'Invoice Number'}: #${collection.invoiceId}',
                  style: boldStyle.copyWith(fontSize: 10),
                ),
              ),
              if (collection.clientName != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '${isArabic ? 'العميل' : 'Client'}: ${collection.clientName}',
                    style: boldStyle.copyWith(fontSize: 10),
                  ),
                ),
              // _buildFooter(settings, isArabic, baseStyle),
              pw.SizedBox(height: 30),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildUnifiedHeader({
    required String title,
    required String id,
    required String date,
    required AppSettings settings,
    required bool isArabic,
    required pw.MemoryImage? logo,
    required pw.TextStyle boldStyle,
    required pw.TextStyle baseStyle,
  }) {
    return pw.Column(
      children: [
        // Row 1: Logo and Brand Name
        pw.Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: .start,
              children: [
                pw.Text(
                  settings.brandName,
                  style: boldStyle.copyWith(fontSize: 18),
                ),
                pw.Text(
                  settings.address,
                  style: baseStyle.copyWith(fontSize: 8),
                ),
                pw.Text(settings.phone, style: baseStyle.copyWith(fontSize: 8)),
              ],
            ),
            if (logo != null) ...[
              pw.SizedBox(width: 4),
              pw.Container(width: 70, child: pw.Image(logo)),
            ],
          ],
        ),
        pw.SizedBox(height: 4),
        // Row 2: Centered Details
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                title,
                style: boldStyle.copyWith(
                  fontSize: 10,
                  color: PdfColors.blue700,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                '${isArabic ? 'الرقم' : 'No'}: #$id',
                style: baseStyle.copyWith(fontSize: 9),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                '${isArabic ? 'التاريخ' : 'Date'}: $date',
                style: baseStyle.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.Divider(thickness: 0.5),
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
      isArabic ? 'الكمية' : 'Qty',
      isArabic ? 'السعر' : 'Price',
      isArabic ? 'الإجمالي' : 'Total',
    ];

    final data = invoice.items.map((item) {
      return [
        item.productName,
        item.qty.toString(),
        item.unitPrice.toStringAsFixed(2),
        item.lineTotal.toStringAsFixed(2),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: boldStyle.copyWith(color: PdfColors.white, fontSize: 7),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellStyle: baseStyle.copyWith(fontSize: 8),
      cellPadding: const pw.EdgeInsets.all(2),
      cellHeight: 20,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
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
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.SizedBox(
        width: 150,
        child: pw.Column(
          children: [
            _buildTotalRow(
              isArabic ? 'المجموع الفرعي' : 'Subtotal',
              invoice.subtotal,
              settings.currency,
              baseStyle.copyWith(fontSize: 10),
            ),
            _buildTotalRow(
              '${isArabic ? 'الضريبة' : 'VAT'} (${invoice.vatPercent}%)',
              invoice.vatAmount,
              settings.currency,
              baseStyle.copyWith(fontSize: 10),
            ),
            pw.Divider(thickness: 0.5),
            _buildTotalRow(
              isArabic ? 'الإجمالي' : 'Total',
              invoice.total,
              settings.currency,
              boldStyle.copyWith(fontSize: 11),
              isBold: true,
            ),
            if (invoice.remainingAmount > 0) ...[
              pw.Divider(thickness: 0.5),
              _buildTotalRow(
                isArabic ? 'المدفوع' : 'Paid',
                invoice.paidAmount,
                settings.currency,
                baseStyle.copyWith(fontSize: 10),
              ),
              _buildTotalRow(
                isArabic ? 'المتبقي' : 'Remaining',
                invoice.remainingAmount,
                settings.currency,
                boldStyle.copyWith(fontSize: 11),
                isBold: true,
              ),
            ],
            pw.SizedBox(height: 8),
            pw.Text(
              '${isArabic ? 'طريقة الدفع' : 'Payment'}: ${invoice.paymentMethod.label(isArabic)}',
              style: baseStyle.copyWith(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    double value,
    String currency,
    pw.TextStyle style, {
    bool isBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text('${value.toStringAsFixed(2)} $currency', style: style),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double value,
    String currency,
    pw.TextStyle boldStyle,
    pw.TextStyle baseStyle, {
    bool isBold = false,
    double fontSize = 10,
  }) {
    final style = isBold
        ? boldStyle.copyWith(fontSize: fontSize)
        : baseStyle.copyWith(fontSize: fontSize);
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
