import 'text_box.dart';
import 'medication_box.dart';

class PrescriptionPageModel {
  final int pageNumber;
  final List<TextBox> staticBoxes;
  final List<MedicationBox> dynamicBoxes;

  PrescriptionPageModel({
    required this.pageNumber,
    required this.staticBoxes,
    this.dynamicBoxes = const [],
  });

  void dispose() {
    for (var box in staticBoxes) {
      box.controller.dispose();
    }
    for (var box in dynamicBoxes) {
      box.medicineController.dispose();
      box.dosageController.dispose();
      box.durationController.dispose();
    }
  }
}
