import 'package:digital_prescription/database/database_helper.dart';
import 'package:digital_prescription/models/medicine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../controllers/prescription_controller.dart';
import '../models/text_box.dart';
import '../models/medication_box.dart';
import '../models/prescription_page_model.dart';

class PrescriptionPage extends StatelessWidget {
  final int pageIndex;
  final PrescriptionPageModel pageModel;
  final PrescriptionController controller;

  const PrescriptionPage({
    Key? key,
    required this.pageIndex,
    required this.pageModel,
    required this.controller,
  }) : super(key: key);

  Widget _buildTextBox(TextBox box, double scale) {
    final isSingleLineStatic = ['patient_name', 'age', 'date'].contains(box.id);

    // Scale font size and other properties to maintain visual consistency
    final double baseFontSize = 14.0;
    final scaledFontSize = baseFontSize * scale;

    final staticTextField = TextField(
      controller: box.controller,
      maxLines: isSingleLineStatic ? 1 : 10,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(fontSize: scaledFontSize),
      decoration: InputDecoration(
        border: InputBorder.none,
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
    final double baseFontSize = 14.0;
    final scaledFontSize = baseFontSize * scale;

    return Positioned(
      left: box.position.left * scale,
      top: box.position.top * scale,
      width: box.position.width * 1.1 * scale, // Increased width
      height: box.position.height * 1.1 * scale, // Increased height
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
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
                  // Medicine name field with autocomplete
                  Expanded(
                    flex: 3,
                    child: TypeAheadField<Medicine>(
                      suggestionsCallback: (pattern) async {
                        return await DatabaseHelper().searchMedicines(pattern);
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(
                            suggestion.name,
                            style: TextStyle(fontSize: scaledFontSize),
                          ),
                        );
                      },
                      onSelected: (suggestion) {
                        box.medicineController.text = suggestion.name;
                      },
                      controller: box.medicineController,
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: TextStyle(
                            fontSize: scaledFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Medicine name...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10 * scale,
                              vertical: 8 * scale,
                            ),
                            isDense: true,
                          ),
                        );
                      },
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
                          width: 100 * scale,
                          child: TextField(
                            controller: box.dosageController,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: scaledFontSize),
                            decoration: InputDecoration(
                              hintText: '1+0+1',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
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
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: scaledFontSize),
                            decoration: InputDecoration(
                              hintText: '7 days',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
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
            Positioned(
              right: -10,
              top: -10,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    Icons.remove_circle,
                    color: Colors.redAccent,
                    size: 24 * scale,
                  ),
                  onPressed: () =>
                      controller.deleteDynamicBox(pageIndex, box.id),
                  splashRadius: 20 * scale,
                  tooltip: 'Delete',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          image: AssetImage('assets/images/bg.jpg'),
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
          ...pageModel.staticBoxes.map((box) => _buildTextBox(box, scale)),
          // Dynamic boxes (medication boxes) from the current page
          ...pageModel.dynamicBoxes.map(
            (box) => _buildMedicationBox(box, scale),
          ),
          // Add medication button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                controller.addDynamicBox();
              },
              child: Icon(Icons.add),
              tooltip: 'Add Medication',
              mini: true,
            ),
          ),
        ],
      ),
    );
  }
}
