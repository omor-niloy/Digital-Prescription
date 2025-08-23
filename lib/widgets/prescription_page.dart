import 'package:flutter/material.dart';
import '../controllers/prescription_controller.dart';
import '../models/text_box.dart';
import '../models/medication_box.dart';
import '../models/prescription_page_model.dart';

class PrescriptionPage extends StatefulWidget {
  final int pageIndex;
  final PrescriptionPageModel pageModel;
  final PrescriptionController controller;

  const PrescriptionPage({
    Key? key,
    required this.pageIndex,
    required this.pageModel,
    required this.controller,
  }) : super(key: key);

  @override
  _PrescriptionPageState createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  @override
  void initState() {
    super.initState();
    // Remove the setOnUpdate call here to avoid overriding the HomePage's callback
  }

  Widget _buildTextBox(TextBox box, double scale) {
    final isSingleLineStatic = [
      'patient_name',
      'age',
      'date',
      'address',
    ].contains(box.id);

    // Scale font size and other properties to maintain visual consistency
    final double baseFontSize = 16.0;
    final scaledFontSize = baseFontSize * scale;

    final staticTextField = TextField(
      controller: box.controller,
      readOnly: true, // Make the text field read-only
      maxLines: isSingleLineStatic ? 1 : 10,
      // textAlignVertical: TextAlignVertical.center,
      style: TextStyle(fontSize: scaledFontSize),
      decoration: InputDecoration(
        border: InputBorder.none,
        // border: OutlineInputBorder(
        //   borderSide: BorderSide(color: Colors.grey.shade300),
        // ),
        isDense: true,
        contentPadding: EdgeInsets.all(8 * scale), // Scale padding
      ),
    );

    return Positioned(
      left: box.position.left * scale,
      top: box.position.top * scale,
      width: box.position.width * scale,
      height: box.position.height * scale,
      child: staticTextField,
    );
  }

  Widget _buildMedicationBox(MedicationBox box, double scale) {
    final double baseFontSize = 16.0;
    final scaledFontSize = baseFontSize * scale;

    return Positioned(
      left: box.position.left * scale,
      top: box.position.top * scale,
      width: box.position.width * 1.1 * scale, // Increased width
      height: box.position.height * 1.1 * scale, // Increased height
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.0),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.all(12 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine name field (read-only)
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: box.medicineController,
                      readOnly: true,
                      style: TextStyle(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        // hintText: 'Medicine name...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10 * scale,
                          vertical: 8 * scale,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  // Dosage and duration row
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20 * scale,
                        ), // Move dosage box to the right
                        // Dosage field
                        SizedBox(
                          width: 120 * scale, // Increased width for dosage
                          child: TextField(
                            controller: box.dosageController,
                            readOnly: true,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: scaledFontSize),
                            decoration: InputDecoration(
                              // hintText: '0+0+0',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8 * scale,
                                horizontal: 4 * scale,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Add spacing
                        // Food instruction field
                        SizedBox(
                          width: 100 * scale,
                          child: TextField(
                            controller: box.foodInstructionController,
                            readOnly: true,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: scaledFontSize),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              // border: OutlineInputBorder(
                              //   borderSide: BorderSide(
                              //     color: Colors.grey.shade300,
                              //   ),
                              // ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8 * scale,
                                horizontal: 4 * scale,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const Spacer(), // Pushes the next widget to the end
                        // Duration field
                        SizedBox(
                          width: 100 * scale,
                          child: TextField(
                            controller: box.durationController,
                            readOnly: true,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: scaledFontSize),
                            decoration: InputDecoration(
                              // hintText: 'days',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8 * scale,
                                horizontal: 4 * scale,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Delete button
            // Positioned(
            //   right: -10,
            //   top: -10,
            //   child: Material(
            //     color: Colors.transparent,
            //     child: IconButton(
            //       icon: Icon(
            //         Icons.remove_circle,
            //         color: Colors.redAccent,
            //         size: 24 * scale,
            //       ),
            //       onPressed: () => widget.controller.deleteDynamicBox(box.id),
            //       splashRadius: 20 * scale,
            //       tooltip: 'Delete',
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // void _updateDosageDisplay(MedicationBox box) {
  //   final morningValue = box.isMorning ? '1' : '0';
  //   final noonValue = box.isNoon ? '1' : '0';
  //   final nightValue = box.isNight ? '1' : '0';
  //   box.dosageController.text = '$morningValue+$noonValue+$nightValue';
  //   widget.controller.updateDosage(
  //     widget.pageIndex,
  //     box.id,
  //     box.isMorning,
  //     box.isNoon,
  //     box.isNight,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double designWidth = 800;
    const double designHeight = 1120;
    const double maxWidth = 800;

    // Use horizontal padding for better layout on mobile
    final horizontalPadding = screenWidth > (maxWidth + 80)
        ? (screenWidth - maxWidth) / 2
        : 16.0;
    final availableWidth = screenWidth - (2 * horizontalPadding);

    final pageWidth = availableWidth > maxWidth ? maxWidth : availableWidth;
    final scale = pageWidth / designWidth;
    final pageHeight = designHeight * scale;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      width: pageWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        image: const DecorationImage(
          image: AssetImage('assets/images/bg_v3.png'),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Static boxes from the current page
          ...widget.pageModel.staticBoxes.map(
            (box) => _buildTextBox(box, scale),
          ),
          // Dynamic boxes (medication boxes) from the current page
          ...widget.pageModel.dynamicBoxes.map(
            (box) => _buildMedicationBox(box, scale),
          ),
        ],
      ),
    );
  }
}
