import 'package:digital_prescription/database/database_helper.dart';
import 'package:digital_prescription/models/medicine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../controllers/prescription_controller.dart';
import '../models/medication_box.dart';

class PatientInfoPanel extends StatefulWidget {
  final PrescriptionController controller;

  const PatientInfoPanel({Key? key, required this.controller})
    : super(key: key);

  @override
  State<PatientInfoPanel> createState() => _PatientInfoPanelState();
}

class _PatientInfoPanelState extends State<PatientInfoPanel> {
  String? selectedGender;
  late FocusNode _ccFocusNode;
  late FocusNode _oeFocusNode;

  @override
  void initState() {
    super.initState();
    if (widget.controller.genderController.text.isNotEmpty) {
      selectedGender = widget.controller.genderController.text;
    }
    _ccFocusNode = FocusNode();
    _oeFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _ccFocusNode.dispose();
    _oeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller.patientNameController,
            decoration: const InputDecoration(
              labelText: 'Patient Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller.ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      selectedGender = value;
                      widget.controller.genderController.text = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller.phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller.dateController,
            decoration: const InputDecoration(
              labelText: 'Date',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: false, // Date is auto-filled
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller.addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            'Clinical Notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TypeAheadField<String>(
            controller: widget.controller.ccController,
            suggestionsCallback: (pattern) async {
              // Get the current line being typed
              final controller = widget.controller.ccController;
              final text = controller.text;
              final cursorPos = controller.selection.start;

              // Find the current line
              final lines = text.substring(0, cursorPos).split('\n');
              final currentLine = lines.isNotEmpty ? lines.last : '';

              if (currentLine.trim().isEmpty) {
                // Show top 5 items when field is empty
                return (await DatabaseHelper().getChiefComplaints(
                  limit: 5,
                )).map((e) => e.name).toList();
              }

              // Search based on current line
              final results = await DatabaseHelper().searchChiefComplaints(
                currentLine.trim(),
              );
              return results.map((e) => e.name).toList();
            },
            itemBuilder: (context, suggestion) {
              return ListTile(title: Text(suggestion));
            },
            onSelected: (suggestion) {
              final controller = widget.controller.ccController;
              final text = controller.text;
              final cursorPos = controller.selection.start;

              // Find line start (go back to find last \n or start of text)
              int lineStart = 0;
              for (int i = cursorPos - 1; i >= 0; i--) {
                if (text[i] == '\n') {
                  lineStart = i + 1;
                  break;
                }
              }

              // Find line end (go forward to find next \n or end of text)
              int lineEnd = text.length;
              for (int i = cursorPos; i < text.length; i++) {
                if (text[i] == '\n') {
                  lineEnd = i;
                  break;
                }
              }

              // Replace current line with suggestion
              final beforeLine = text.substring(0, lineStart);
              final afterLine = text.substring(lineEnd);
              final newText = beforeLine + suggestion + '\n' + afterLine;

              controller.text = newText;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: beforeLine.length + suggestion.length + 1),
              );
            },
            builder: (context, controller, focusNode) {
              _ccFocusNode = focusNode;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'C/C (Chief Complaints)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              );
            },
          ),
          const SizedBox(height: 12),
          TypeAheadField<String>(
            controller: widget.controller.oeController,
            suggestionsCallback: (pattern) async {
              // Get the current line being typed
              final controller = widget.controller.oeController;
              final text = controller.text;
              final cursorPos = controller.selection.start;

              // Find the current line
              final lines = text.substring(0, cursorPos).split('\n');
              final currentLine = lines.isNotEmpty ? lines.last : '';

              if (currentLine.trim().isEmpty) {
                // Show top 5 items when field is empty
                return (await DatabaseHelper().getOnExaminations(
                  limit: 5,
                )).map((e) => e.name).toList();
              }

              // Search based on current line
              final results = await DatabaseHelper().searchOnExaminations(
                currentLine.trim(),
              );
              return results.map((e) => e.name).toList();
            },
            itemBuilder: (context, suggestion) {
              return ListTile(title: Text(suggestion));
            },
            onSelected: (suggestion) {
              final controller = widget.controller.oeController;
              final text = controller.text;
              final cursorPos = controller.selection.start;

              // Find line start (go back to find last \n or start of text)
              int lineStart = 0;
              for (int i = cursorPos - 1; i >= 0; i--) {
                if (text[i] == '\n') {
                  lineStart = i + 1;
                  break;
                }
              }

              // Find line end (go forward to find next \n or end of text)
              int lineEnd = text.length;
              for (int i = cursorPos; i < text.length; i++) {
                if (text[i] == '\n') {
                  lineEnd = i;
                  break;
                }
              }

              // Replace current line with suggestion
              final beforeLine = text.substring(0, lineStart);
              final afterLine = text.substring(lineEnd);
              final newText = beforeLine + suggestion + '\n' + afterLine;

              controller.text = newText;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: beforeLine.length + suggestion.length + 1),
              );
            },
            builder: (context, controller, focusNode) {
              _oeFocusNode = focusNode;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'O/E (On Examination)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller.advController,
            decoration: const InputDecoration(
              labelText: 'Adv (Advice)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Text('Medications', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          // Use a ListView.builder for a dynamic list of medication forms
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.controller.getAllDynamicBoxes().length,
            itemBuilder: (context, index) {
              final box = widget.controller.getAllDynamicBoxes()[index];
              return _buildMedicationCard(box);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.controller.addDynamicBox,
              icon: const Icon(Icons.add),
              label: const Text('Add Medication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(MedicationBox box) {
    // Using ObjectKey ensures that Flutter creates a new widget with fresh state
    // when the MedicationBox instance changes, preventing issues with stale controllers.
    return Card(
      key: ObjectKey(box),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medication #${int.parse(box.id.split('_').last) + 1}', // Simple numbering
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => widget.controller.deleteDynamicBox(box.id),
                  tooltip: 'Delete Medication',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // First row: Medicine name and Duration
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TypeAheadField<Medicine>(
                    suggestionsCallback: (pattern) async {
                      return await DatabaseHelper().searchMedicines(pattern);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(title: Text(suggestion.name));
                    },
                    onSelected: (suggestion) {
                      // Safety check: ensure the box and its controller haven't been disposed
                      if (widget.controller.getAllDynamicBoxes().any(
                        (b) => b.id == box.id,
                      )) {
                        box.medicineController.text = suggestion.name;
                      }
                    },
                    controller: box.medicineController,
                    builder: (context, controller, focusNode) {
                      // The 'controller' here is the one managed by TypeAheadField,
                      // which is safer to use than the one from the 'box' closure.
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: box.durationController,
                    decoration: const InputDecoration(
                      labelText: 'Days',
                      // hintText: 'days',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && !value.contains('days')) {
                        final number = value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (number.isNotEmpty) {
                          box.durationController.value = TextEditingValue(
                            text: '$number days',
                            selection: TextSelection.collapsed(
                              offset: number.length,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Second row: Dosage and Food instruction
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: box.dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                _buildDosageDropdown(box),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: box.foodInstructionController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Food',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                _buildFoodInstructionDropdown(box),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageDropdown(MedicationBox box) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.arrow_drop_down),
      tooltip: 'Select Dosage',
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Morning'),
                    value: box.isMorning,
                    onChanged: (bool? value) {
                      setState(() {
                        box.isMorning = value ?? false;
                      });
                      _updateDosageDisplay(box);
                    },
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                  CheckboxListTile(
                    title: const Text('Noon'),
                    value: box.isNoon,
                    onChanged: (bool? value) {
                      setState(() {
                        box.isNoon = value ?? false;
                      });
                      _updateDosageDisplay(box);
                    },
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                  CheckboxListTile(
                    title: const Text('Night'),
                    value: box.isNight,
                    onChanged: (bool? value) {
                      setState(() {
                        box.isNight = value ?? false;
                      });
                      _updateDosageDisplay(box);
                    },
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFoodInstructionDropdown(MedicationBox box) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.arrow_drop_down),
      tooltip: 'Select Food Instruction',
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'none',
          child: const Text('None'),
          onTap: () {
            widget.controller.updateFoodInstruction(box.id, 'none');
          },
        ),
        PopupMenuItem<String>(
          value: 'খাবার আগে',
          child: const Text('খাবার আগে'),
          onTap: () {
            widget.controller.updateFoodInstruction(box.id, 'খাবার আগে');
          },
        ),
        PopupMenuItem<String>(
          value: 'খাবার পরে',
          child: const Text('খাবার পরে'),
          onTap: () {
            widget.controller.updateFoodInstruction(box.id, 'খাবার পরে');
          },
        ),
      ],
    );
  }

  void _updateDosageDisplay(MedicationBox box) {
    final morning = box.isMorning ? '1' : '0';
    final noon = box.isNoon ? '1' : '0';
    final night = box.isNight ? '1' : '0';
    box.dosageController.text = '$morning+$noon+$night';
    // No need to call controller update here as the controller's instance is being directly manipulated
  }
}
