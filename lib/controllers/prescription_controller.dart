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
  late final TextEditingController ccController;
  late final TextEditingController oeController;
  late final TextEditingController advController;

  // Define the layout for the static boxes
  final Map<String, Rect> _staticBoxLayout = {
    'patient_name': const Rect.fromLTWH(85, 244, 155, 30),
    'age': const Rect.fromLTWH(300, 244, 80, 30),
    'address': const Rect.fromLTWH(450, 244, 195, 30), // Address field
    'date': const Rect.fromLTWH(650, 244, 130, 30),
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
  final int _initialBoxes = 1;

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
    ccController = TextEditingController();
    oeController = TextEditingController();
    advController = TextEditingController();

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
        case 'C/C':
          controller = ccController;
          break;
        case 'O/E':
          controller = oeController;
          break;
        case 'Adv':
          controller = advController;
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
      for (int i = 0; i < _initialBoxes; i++) {
        final newY =
            _dynamicBoxStartY + i * (_dynamicBoxHeight + _dynamicBoxSpacing);
        defaultDynamicBoxes.add(
          MedicationBox(
            id: 'dynamic_${pageNumber}_$i',
            medicineController: TextEditingController(),
            dosageController: TextEditingController(),
            durationController: TextEditingController(),
            foodInstructionController: TextEditingController(),
            position: Rect.fromLTWH(330, newY, 400, _dynamicBoxHeight),
            isMorning: false,
            isNoon: false,
            isNight: false,
            foodInstruction: "none",
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

  void deleteDynamicBox(String boxId) {
    for (final page in pages) {
      final boxIndex = page.dynamicBoxes.indexWhere((b) => b.id == boxId);
      if (boxIndex != -1) {
        final box = page.dynamicBoxes[boxIndex];
        box.medicineController.dispose();
        box.dosageController.dispose();
        box.durationController.dispose();
        box.foodInstructionController.dispose();
        page.dynamicBoxes.removeAt(boxIndex);
        _reflowDynamicBoxes();
        return; // Found and deleted, so exit.
      }
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
        foodInstructionController: TextEditingController(),
        position: Rect.zero, // Temporary position
        isMorning: false,
        isNoon: false,
        isNight: false,
        foodInstruction: "none",
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
          foodInstructionController: box.foodInstructionController,
          position: Rect.fromLTWH(330, newY, 400, _dynamicBoxHeight),
          isMorning: box.isMorning,
          isNoon: box.isNoon,
          isNight: box.isNight,
          foodInstruction: box.foodInstruction,
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
            box.controller == dateController ||
            box.controller == ccController ||
            box.controller == oeController ||
            box.controller == advController;

        if (!isSharedController) {
          box.controller.dispose();
        }
      }
      pages.removeLast();
    }

    onUpdate?.call();
  }

  void updateDosage(
    int pageIndex,
    String boxId,
    bool morning,
    bool noon,
    bool night,
  ) {
    if (pageIndex < 0 || pageIndex >= pages.length) return;

    final page = pages[pageIndex];
    final boxIndex = page.dynamicBoxes.indexWhere((box) => box.id == boxId);

    if (boxIndex != -1) {
      final box = page.dynamicBoxes[boxIndex];
      box.isMorning = morning;
      box.isNoon = noon;
      box.isNight = night;

      // Update the dosage text field with the 1+0+1 format
      final morningValue = morning ? '1' : '0';
      final noonValue = noon ? '1' : '0';
      final nightValue = night ? '1' : '0';
      box.dosageController.text = '$morningValue+$noonValue+$nightValue';

      onUpdate?.call();
    }
  }

  void updateFoodInstruction(String boxId, String instruction) {
    for (final page in pages) {
      final boxIndex = page.dynamicBoxes.indexWhere((box) => box.id == boxId);
      if (boxIndex != -1) {
        final box = page.dynamicBoxes[boxIndex];
        box.foodInstruction = instruction;
        box.foodInstructionController.text = instruction == "none"
            ? ""
            : instruction;
        onUpdate?.call();
        return;
      }
    }
  }

  List<MedicationBox> getAllDynamicBoxes() {
    return pages.expand((page) => page.dynamicBoxes).toList();
  }

  void dispose() {
    // Dispose the central controllers
    patientNameController.dispose();
    ageController.dispose();
    genderController.dispose();
    phoneController.dispose();
    dateController.dispose();
    addressController.dispose();
    ccController.dispose();
    oeController.dispose();
    advController.dispose();

    for (var page in pages) {
      // Dispose only the controllers that are not central
      for (var box in page.staticBoxes) {
        if (box.controller != patientNameController &&
            box.controller != ageController &&
            box.controller != addressController &&
            box.controller != dateController &&
            box.controller != ccController &&
            box.controller != oeController &&
            box.controller != advController) {
          box.controller.dispose();
        }
      }
      for (var box in page.dynamicBoxes) {
        box.medicineController.dispose();
        box.dosageController.dispose();
        box.durationController.dispose();
        box.foodInstructionController.dispose();
      }
    }
  }
}
