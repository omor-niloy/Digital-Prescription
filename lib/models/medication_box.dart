import 'package:flutter/material.dart';

class MedicationBox {
  final String id;
  final Rect position;
  final TextEditingController medicineController;
  final TextEditingController dosageController;
  final TextEditingController durationController;
  final TextEditingController foodInstructionController;
  bool isMorning;
  bool isNoon;
  bool isNight;
  String foodInstruction; // "none", "খাবার আগে", "খাবার পরে"

  MedicationBox({
    required this.id,
    required this.position,
    required this.medicineController,
    required this.dosageController,
    required this.durationController,
    required this.foodInstructionController,
    this.isMorning = false,
    this.isNoon = false,
    this.isNight = false,
    this.foodInstruction = "none",
  });
}
