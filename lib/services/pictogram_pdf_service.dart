import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/set_model.dart';

class PictogramPdfService {
  Future<void> printSet(PictogramSet set) async {
    final bytes = await _buildPdf(set);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<Uint8List> _buildPdf(PictogramSet set) async {
    final doc = pw.Document();
    final images = await _loadImages(set);

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 40, bottom: 20),
            child: pw.Text(
              set.name,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          ...List.generate(set.pictograms.length, (index) {
            final pictogram = set.pictograms[index];
            final image = images[index];
            return pw.Padding(
              padding:
                  const pw.EdgeInsets.only(bottom: 8, left: 100, right: 100),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (image != null)
                    pw.Image(image,
                        width: 80, height: 80, fit: pw.BoxFit.contain)
                  else
                    pw.Container(
                      width: 80,
                      height: 80,
                      color: PdfColors.grey200,
                    ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Text(
                      pictogram.keyword,
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            'Je Dag in Beeld - jedaginbeeld.nl',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ),
    );

    return doc.save();
  }

  Future<List<pw.ImageProvider?>> _loadImages(PictogramSet set) async {
    return Future.wait(
      set.pictograms.map((pictogram) async {
        try {
          final uri = Uri.tryParse(pictogram.imageUrl);
          if (uri == null) return null;
          final response = await http.get(uri).timeout(
                const Duration(seconds: 10),
                onTimeout: () => http.Response('', 408),
              );
          if (response.statusCode != 200) return null;
          return pw.MemoryImage(response.bodyBytes);
        } catch (_) {
          return null;
        }
      }),
    );
  }
}
