import 'package:digital_prescription/database/database_helper.dart';
import 'package:digital_prescription/models/medicine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class DrugManagementPage extends StatefulWidget {
  const DrugManagementPage({Key? key}) : super(key: key);

  @override
  State<DrugManagementPage> createState() => _DrugManagementPageState();
}

class _DrugManagementPageState extends State<DrugManagementPage> {
  List<Medicine> _medicines = [];
  List<Medicine> _filteredMedicines = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _searchController.addListener(_filterMedicines);
  }

  Future<void> _loadMedicines() async {
    final medicines = await DatabaseHelper().getAllMedicines();
    if (mounted) {
      setState(() {
        _medicines = medicines;
        _filterMedicines();
      });
    }
  }

  void _filterMedicines() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMedicines = _medicines
          .where((medicine) => medicine.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    if (medicine.id != null) {
      await DatabaseHelper().deleteMedicine(medicine.id!);
      _loadMedicines(); // Refresh the list
    }
  }

  Future<void> _addMedicine(String name) async {
    if (name.isNotEmpty) {
      final newMedicine = Medicine(name: name);
      await DatabaseHelper().insertMedicine(newMedicine);
      _searchController.clear();
      _loadMedicines();
    }
  }

  void _showAddDrugDialog() {
    final TextEditingController addDrugController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Drug'),
          content: TextField(
            controller: addDrugController,
            decoration: const InputDecoration(hintText: "Enter drug name"),
            autofocus: true,
            onSubmitted: (value) {
              _addMedicine(value);
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                _addMedicine(addDrugController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterMedicines);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drug Management')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TypeAheadField<Medicine>(
                    hideOnEmpty: true,
                    suggestionsCallback: (pattern) async {
                      if (pattern.isEmpty) {
                        return [];
                      }
                      return _medicines
                          .where(
                            (m) => m.name.toLowerCase().contains(
                              pattern.toLowerCase(),
                            ),
                          )
                          .toList();
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(title: Text(suggestion.name));
                    },
                    onSelected: (suggestion) {
                      _searchController.text = suggestion.name;
                    },
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: _searchController,
                        focusNode: focusNode,
                        onSubmitted: (_) {
                          // Do nothing to prevent page from closing
                        },
                        decoration: InputDecoration(
                          labelText: 'Search Medicine',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.teal, size: 30),
                  onPressed: _showAddDrugDialog,
                  tooltip: 'Add New Drug',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _filteredMedicines.isEmpty &&
                      _searchController.text.isNotEmpty
                  ? const Center(child: Text('No medicines found.'))
                  : ListView.builder(
                      itemCount: _filteredMedicines.length,
                      itemBuilder: (context, index) {
                        final medicine = _filteredMedicines[index];
                        return Card(
                          child: ListTile(
                            title: Text(medicine.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteMedicine(medicine),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
