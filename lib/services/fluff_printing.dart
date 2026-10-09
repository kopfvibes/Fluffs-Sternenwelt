import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/creative.dart';

class FluffPrinting {
  static Future<Uint8List> book(Iterable<int> pages) async {
    final doc = pw.Document();
    for (final page in pages) {
      final data = await rootBundle.load(coloringAsset(page));
      final image = pw.MemoryImage(data.buffer.asUint8List(
        data.offsetInBytes, data.lengthInBytes));
      doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain))));
    }
    return doc.save();
  }

  static Future<void> output(Uint8List bytes, {required String filename,
    bool share = false}) async {
    if (share) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } else {
      await Printing.layoutPdf(name: filename, onLayout: (_) async => bytes);
    }
  }

  static Future<Uint8List> drawing(Uint8List png) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),
      build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(png),
        fit: pw.BoxFit.contain))));
    return doc.save();
  }
}
