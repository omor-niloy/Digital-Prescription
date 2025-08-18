import 'dart:io';
import 'package:digital_prescription/controllers/prescription_controller.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

class PdfService {
  Future<void> generateAndPrintPrescription(
    PrescriptionController controller,
  ) async {
    // 1. Request necessary permissions
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.storage.request();
      if (status.isDenied) {
        // Handle the case where the user denies permission
        print('Storage permission denied.');
        return;
      }
    }

    // 2. Create the PDF document with a custom theme
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
                  // Match the base font size from the UI
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
                          fontSize: fontSize * 0.75,
                        ), // Adjust for PDF scaling
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
                                font: ttfBold, // Explicitly use the bold font
                                fontSize: 18 * 0.75, // Match UI: 20
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
                                    style: const pw.TextStyle(
                                      fontSize: 16 * 0.75,
                                    ), // Match UI: 16
                                  ),
                                ),
                                pw.SizedBox(width: 10),
                                pw.Container(
                                  width: 100 * scaleX,
                                  child: pw.Text(
                                    medBox.foodInstructionController.text,
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(
                                      fontSize: 16 * 0.75,
                                    ), // Match UI: 16
                                  ),
                                ),
                                pw.Spacer(),
                                pw.Container(
                                  width: 100 * scaleX,
                                  child: pw.Text(
                                    medBox.durationController.text,
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(
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
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
      await prescriptionsDir.create(recursive: true);
    }

    // Create a unique filename
    final patientName = controller.patientNameController.text.replaceAll(
      ' ',
      '_',
    );
    final date = DateTime.now().toIso8601String().split('T').first;
    final filePath = '${prescriptionsDir.path}/${patientName}_${date}.pdf';
    final file = File(filePath);

    // 4. Save the PDF to the file
    await file.writeAsBytes(await pdf.save());
    print('PDF saved to $filePath');

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
