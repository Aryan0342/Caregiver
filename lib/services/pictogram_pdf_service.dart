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
          pw.Text(
            set.name,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.GridView(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: List.generate(set.pictograms.length, (index) {
              final pictogram = set.pictograms[index];
              final image = images[index];
              return pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    if (image != null)
                      pw.Image(image,
                          width: 72, height: 72, fit: pw.BoxFit.contain)
                    else
                      pw.Container(
                        width: 72,
                        height: 72,
                        color: PdfColors.grey200,
                      ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      pictogram.keyword,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
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
          final response = await http.get(uri);
          if (response.statusCode != 200) return null;
          return pw.MemoryImage(response.bodyBytes);
        } catch (_) {
          return null;
        }
      }),
    );
  }
}
