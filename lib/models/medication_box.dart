import 'package:flutter/material.dart';

class MedicationBox {
  final String id;
  final Rect position;
  final TextEditingController medicineController;
  final TextEditingController dosageController;
  final TextEditingController durationController;

  MedicationBox({
    required this.id,
    required this.position,
    required this.medicineController,
    required this.dosageController,
    required this.durationController,
  });
}
