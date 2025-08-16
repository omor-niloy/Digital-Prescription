import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prescription_page_model.dart';
import '../models/text_box.dart';
import '../models/medication_box.dart';

class PrescriptionController {
  List<PrescriptionPageModel> pages = [];
  VoidCallback? onUpdate;

  // Centralized controllers for the patient info panel
  late final TextEditingController patientNameController;
  late final TextEditingController ageController;
  late final TextEditingController genderController;
  late final TextEditingController phoneController;
  late final TextEditingController dateController;
  late final TextEditingController addressController;

  // Define the layout for the static boxes
  final Map<String, Rect> _staticBoxLayout = {
    'patient_name': const Rect.fromLTWH(85, 247, 155, 27),
    'age': const Rect.fromLTWH(300, 247, 80, 27),
    'address': const Rect.fromLTWH(450, 247, 200, 27), // Address field
    'date': const Rect.fromLTWH(650, 247, 130, 27),
    'C/C': const Rect.fromLTWH(50, 340, 195, 180),
    'O/E': const Rect.fromLTWH(50, 560, 195, 120),
    'Adv': const Rect.fromLTWH(50, 720, 195, 200),
    // Add other static boxes here
  };

  // Define the starting position and layout for dynamic boxes
  final double _dynamicBoxStartY = 350;
  final double _dynamicBoxHeight = 80;
  final double _dynamicBoxSpacing = 15;
  final int _maxDynamicBoxesPerPage = 7;

  PrescriptionController() {
    // Initialize the central controllers
    patientNameController = TextEditingController();
    ageController = TextEditingController();
    genderController = TextEditingController();
    phoneController = TextEditingController();
    dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    addressController = TextEditingController();

    _createNewPage();
  }

  void setOnUpdate(VoidCallback callback) {
    onUpdate = callback;
  }

  void _createNewPage() {
    final pageNumber = pages.length + 1;
    final staticBoxes = _staticBoxLayout.entries.map((entry) {
      // Use the central controllers for patient info fields
      TextEditingController controller;
      switch (entry.key) {
        case 'patient_name':
          controller = patientNameController;
          break;
        case 'age':
          controller = ageController;
          break;
        case 'address':
          controller = addressController;
          break;
        case 'date':
          controller = dateController;
          break;
        // Other static boxes get their own controllers
        default:
          controller = TextEditingController();
      }

      return TextBox(
        id: entry.key,
        controller: controller,
        position: entry.value,
        hintText: entry.key.replaceAll('_', ' ').toUpperCase(),
      );
    }).toList();

    // Create 7 default dynamic boxes only for the first page
    final defaultDynamicBoxes = <MedicationBox>[];
    if (pageNumber == 1) {
      for (int i = 0; i < 7; i++) {
        final newY =
            _dynamicBoxStartY + i * (_dynamicBoxHeight + _dynamicBoxSpacing);
        defaultDynamicBoxes.add(
          MedicationBox(
            id: 'dynamic_${pageNumber}_$i',
            medicineController: TextEditingController(),
            dosageController: TextEditingController(),
            durationController: TextEditingController(),
            position: Rect.fromLTWH(330, newY, 400, _dynamicBoxHeight),
          ),
        );
      }
    }

    pages.add(
      PrescriptionPageModel(
        pageNumber: pageNumber,
        staticBoxes: staticBoxes,
        dynamicBoxes: defaultDynamicBoxes,
      ),
    );
  }

  void addDynamicBox() {
    // Reflow will handle page creation if necessary
    _reflowDynamicBoxes(addBox: true);
  }

  void deleteDynamicBox(int pageIndex, String boxId) {
    if (pageIndex < 0 || pageIndex >= pages.length) return;

    final page = pages[pageIndex];
    final boxIndex = page.dynamicBoxes.indexWhere((box) => box.id == boxId);

    if (boxIndex != -1) {
      // Dispose all controllers and remove the box
      final box = page.dynamicBoxes[boxIndex];
      box.medicineController.dispose();
      box.dosageController.dispose();
      box.durationController.dispose();
      page.dynamicBoxes.removeAt(boxIndex);

      // Reflow all other boxes
      _reflowDynamicBoxes();
    }
  }

  void _reflowDynamicBoxes({bool addBox = false}) {
    // Consolidate all existing dynamic boxes into a single list
    final allDynamicBoxes = pages.expand((page) => page.dynamicBoxes).toList();

    // Clear dynamic boxes from all pages
    for (var page in pages) {
      page.dynamicBoxes.clear();
    }

    // If a new box needs to be added, create it now and add to the list
    if (addBox) {
      final newBox = MedicationBox(
        id: 'temp_id_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
        medicineController: TextEditingController(),
        dosageController: TextEditingController(),
        durationController: TextEditingController(),
        position: Rect.zero, // Temporary position
      );
      allDynamicBoxes.add(newBox);
    }

    // Reset to the first page
    int currentPageIndex = 0;

    // Re-distribute all boxes across the pages
    for (var box in allDynamicBoxes) {
      // Check if the current page is full
      if (pages[currentPageIndex].dynamicBoxes.length >=
          _maxDynamicBoxesPerPage) {
        currentPageIndex++;
        // If we need a new page, create one
        if (currentPageIndex >= pages.length) {
          _createNewPage();
        }
      }

      final page = pages[currentPageIndex];
      final newIndexOnPage = page.dynamicBoxes.length;
      final newY =
          _dynamicBoxStartY +
          newIndexOnPage * (_dynamicBoxHeight + _dynamicBoxSpacing);

      // Add the box to the current page with its new position and a stable ID
      page.dynamicBoxes.add(
        MedicationBox(
          id: 'dynamic_${currentPageIndex}_$newIndexOnPage',
          medicineController: box.medicineController,
          dosageController: box.dosageController,
          durationController: box.durationController,
          position: Rect.fromLTWH(330, newY, 400, _dynamicBoxHeight),
        ),
      );
    }

    // Remove any empty pages at the end, but always keep at least one page
    while (pages.length > 1 && pages.last.dynamicBoxes.isEmpty) {
      final pageToRemove = pages.last;
      // Dispose only the controllers that are unique to this page
      for (var box in pageToRemove.staticBoxes) {
        final isSharedController =
            box.controller == patientNameController ||
            box.controller == ageController ||
            box.controller == addressController ||
            box.controller == dateController;

        if (!isSharedController) {
          box.controller.dispose();
        }
      }
      pages.removeLast();
    }

    onUpdate?.call();
  }

  void dispose() {
    // Dispose the central controllers
    patientNameController.dispose();
    ageController.dispose();
    genderController.dispose();
    phoneController.dispose();
    dateController.dispose();
    addressController.dispose();

    for (var page in pages) {
      // Dispose only the controllers that are not central
      for (var box in page.staticBoxes) {
        if (box.controller != patientNameController &&
            box.controller != ageController &&
            box.controller != addressController &&
            box.controller != dateController) {
          box.controller.dispose();
        }
      }
      for (var box in page.dynamicBoxes) {
        box.medicineController.dispose();
        box.dosageController.dispose();
        box.durationController.dispose();
      }
    }
  }
}
