import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfToImageService {
  static Future<Uint8List> convertFirstPageToImage(Uint8List pdfBytes) async {
    final images = Printing.raster(pdfBytes, pages: [0], dpi: 200);

    await for (final page in images) {
      // Get the raw image
      final img = await page.toImage();

      // Composite onto white background to flatten transparency
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White fill
      canvas.drawRect(
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Paint()..color = Colors.white,
      );

      // Draw the PDF page on top
      canvas.drawImage(img, Offset.zero, Paint());

      final picture = recorder.endRecording();
      final flattened = await picture.toImage(img.width, img.height);
      final byteData = await flattened.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData!.buffer.asUint8List();
    }

    throw Exception("No pages found in PDF");
  }
}
