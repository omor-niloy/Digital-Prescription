import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart' as painting;
import 'package:digital_prescription/controllers/prescription_controller.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

class PdfService {
  bool _containsBengali(String s) {
    if (s.isEmpty) return false;
    return RegExp(r'[\u0980-\u09FF]').hasMatch(s);
  }

  Future<Uint8List> _renderTextToPng({
    required String text,
    required double maxWidthPx,
    required double fontSizePx,
    bool bold = false,
    TextAlign align = TextAlign.left,
    int maxLines = 3,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final tp = painting.TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: maxLines,
      ellipsis: null,
      text: painting.TextSpan(
        text: text,
        style: painting.TextStyle(
          fontFamily: 'NotoSansBengali',
          fontSize: fontSizePx,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: const Color(0xFF000000),
        ),
      ),
    );
    tp.layout(maxWidth: maxWidthPx);

    final textSize = tp.size;
    // Add a tiny padding to avoid clipping
    final imgW = textSize.width.ceil() + 4;
    final imgH = textSize.height.ceil() + 4;

    final bgPaint = painting.Paint()..color = const Color(0x00000000);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble()),
      bgPaint,
    );
    tp.paint(canvas, const Offset(2, 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(imgW, imgH);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> generateAndPrintPrescription(
    PrescriptionController controller,
  ) async {
    // 1. Request necessary permissions
    if (Platform.isAndroid) {
      // Request multiple permissions for Android
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      // Check if at least one storage permission is granted
      bool hasStoragePermission =
          statuses[Permission.storage]?.isGranted == true ||
          statuses[Permission.manageExternalStorage]?.isGranted == true;

      if (!hasStoragePermission) {
        print('Storage permission denied. Cannot save PDF.');
        return;
      }
    } else if (Platform.isIOS) {
      var status = await Permission.storage.request();
      if (status.isDenied) {
        print('Storage permission denied.');
        return;
      }
    }

    // 2. Create the PDF document with a custom Bengali font (Noto Sans Bengali)
    final regularFontData = await rootBundle.load(
      'assets/fonts/HindSiliguri-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/HindSiliguri-Bold.ttf',
    );

    final ttfRegular = pw.Font.ttf(regularFontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
    );

    // Load the background image from assets
    final imageBytes = await rootBundle.load('assets/images/bg.jpg');
    final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

    // A4 page dimensions
    const double a4Width = 21.0 * PdfPageFormat.cm;
    const double a4Height = 29.7 * PdfPageFormat.cm;

    // Dimensions from your PrescriptionPage widget (approximated)
    const double originalWidth = 800;
    const double originalHeight = 1131;

    // Scaling factors
    const double scaleX = a4Width / originalWidth;
    const double scaleY = a4Height / originalHeight;

    // Generate a page for each page in the controller
    for (var pageModel in controller.pages) {
      // Pre-render only the FOOD text if it contains Bengali
      final Map<String, pw.MemoryImage> foodImages = {};
      for (final medBox in pageModel.dynamicBoxes) {
        final food = medBox.foodInstructionController.text;
        if (_containsBengali(food)) {
          final targetWidthPt = 100 * scaleX;
          final widthPx = (targetWidthPt * 3).clamp(60, 4000).toDouble();
          final fontSizePt = 18 * 0.75;
          final fontSizePx = (fontSizePt * 3);
          final bytes = await _renderTextToPng(
            text: food,
            maxWidthPx: widthPx,
            fontSizePx: fontSizePx,
            align: TextAlign.center,
            maxLines: 1,
          );
          foodImages[medBox.id] = pw.MemoryImage(bytes);
        }
      }
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Background image
                pw.Image(image, fit: pw.BoxFit.fill),

                // Static text boxes (patient info, clinical notes)
                ...pageModel.staticBoxes.map((box) {
                  double fontSize = 16.0;
                  return pw.Positioned(
                    left: box.position.left * scaleX,
                    top: box.position.top * scaleY,
                    child: pw.Container(
                      width: box.position.width * scaleX,
                      height: box.position.height * scaleY,
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        box.controller.text,
                        style: pw.TextStyle(
                          font: ttfRegular,
                          fontSize: fontSize * 0.75,
                        ),
                      ),
                    ),
                  );
                }),

                // Dynamic medication boxes
                ...pageModel.dynamicBoxes.map((medBox) {
                  return pw.Positioned(
                    left: medBox.position.left * scaleX,
                    top: medBox.position.top * scaleY,
                    child: pw.Container(
                      width: medBox.position.width * 1.1 * scaleX,
                      height: medBox.position.height * 1.1 * scaleY,
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              medBox.medicineController.text,
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 18 * 0.75,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Row(
                              children: [
                                pw.SizedBox(width: 20),
                                pw.Container(
                                  width: 120 * scaleX,
                                  child: pw.Text(
                                    medBox.dosageController.text,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                      font: ttfRegular,
                                      fontSize: 16 * 0.75,
                                    ), // Match UI: 16
                                  ),
                                ),
                                pw.SizedBox(width: 10),
                                pw.Container(
                                  width: 100 * scaleX,
                                  alignment: pw.Alignment.center,
                                  child: foodImages.containsKey(medBox.id)
                                      ? pw.Image(
                                          foodImages[medBox.id]!,
                                          fit: pw.BoxFit.contain,
                                        )
                                      : pw.Text(
                                          medBox.foodInstructionController.text,
                                          textAlign: pw.TextAlign.center,
                                          style: pw.TextStyle(
                                            font: ttfRegular,
                                            fontSize: 16 * 0.75,
                                          ),
                                        ),
                                ),
                                pw.Spacer(),
                                pw.Container(
                                  width: 100 * scaleX,
                                  child: pw.Text(
                                    medBox.durationController.text,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                      font: ttfRegular,
                                      fontSize: 16 * 0.75,
                                    ), // Match UI: 16
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );
    }

    // 3. Get the directory to save the file
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        // Try external storage first, fall back to app documents
        try {
          directory = await getExternalStorageDirectory();
          if (directory == null) {
            directory = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          print("External storage not available, using app documents: $e");
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        directory = await getDownloadsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      print("Could not get the directory: $e");
      return;
    }

    if (directory == null) {
      print("Could not get the directory.");
      return;
    }

    final prescriptionsDir = Directory('${directory.path}/Prescriptions');
    if (!await prescriptionsDir.exists()) {
      try {
        await prescriptionsDir.create(recursive: true);
        print('Created prescriptions directory: ${prescriptionsDir.path}');
      } catch (e) {
        print('Failed to create prescriptions directory: $e');
        return;
      }
    }

    // Create a unique filename
    final patientName = controller.patientNameController.text.trim().replaceAll(
      ' ',
      '_',
    );
    final numberRaw = controller.phoneController.text.trim();
    final number = numberRaw.isEmpty
        ? 'NA'
        : numberRaw.replaceAll(RegExp(r'\s+'), '');
    final date = DateTime.now().toIso8601String().split('T').first;
    final filePath =
        '${prescriptionsDir.path}/${number}_${patientName}_${date}.pdf';
    final file = File(filePath);

    // 4. Save the PDF to the file
    try {
      await file.writeAsBytes(await pdf.save());
      print('PDF saved successfully to: $filePath');
    } catch (e) {
      print('Failed to save PDF: $e');
      return;
    }

    // 5. Send the PDF to the printer
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => file.readAsBytes(),
      );
      print('Print job sent.');
    } catch (e) {
      print('Could not send to printer: $e');
    }
  }
}
