import 'package:digital_prescription/database/database_helper.dart';
import 'package:digital_prescription/models/chief_complaint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class CcManagementPage extends StatefulWidget {
  const CcManagementPage({Key? key}) : super(key: key);

  @override
  State<CcManagementPage> createState() => _CcManagementPageState();
}

class _CcManagementPageState extends State<CcManagementPage> {
  List<ChiefComplaint> _ccs = [];
  List<ChiefComplaint> _filteredCcs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCcs();
    _searchController.addListener(_filterCcs);
  }

  Future<void> _loadCcs() async {
    final ccs = await DatabaseHelper().getChiefComplaints(limit: 20);
    if (mounted) {
      setState(() {
        _ccs = ccs;
        _filterCcs();
      });
    }
  }

  void _filterCcs() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      // Show only first 20 items when no search query
      setState(() {
        _filteredCcs = _ccs;
      });
    } else {
      // Show all matching items when searching
      _loadAllCcsForSearch();
    }
  }

  Future<void> _loadAllCcsForSearch() async {
    final allCcs = await DatabaseHelper().getAllChiefComplaints();
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCcs = allCcs
          .where((cc) => cc.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _deleteCc(ChiefComplaint cc) async {
    if (cc.id != null) {
      await DatabaseHelper().deleteChiefComplaint(cc.id!);
      _loadCcs(); // Refresh the list
    }
  }

  Future<void> _addCc(String name) async {
    if (name.isNotEmpty) {
      final newCc = ChiefComplaint(name: name);
      await DatabaseHelper().insertChiefComplaint(newCc);
      _searchController.clear();
      _loadCcs();
    }
  }

  void _showAddCcDialog() {
    final TextEditingController addCcController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Chief Complaint'),
          content: TextField(
            controller: addCcController,
            decoration: const InputDecoration(hintText: "Enter chief complaint"),
            autofocus: true,
            onSubmitted: (value) {
              _addCc(value);
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
                _addCc(addCcController.text);
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
    _searchController.removeListener(_filterCcs);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chief Complaint Management')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TypeAheadField<ChiefComplaint>(
                    hideOnEmpty: true,
                    suggestionsCallback: (pattern) async {
                      if (pattern.isEmpty) {
                        return [];
                      }
                      return _ccs
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
                          labelText: 'Search Chief Complaint',
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
                ElevatedButton(
                  onPressed: _showAddCcDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Add C/C'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _filteredCcs.isEmpty &&
                      _searchController.text.isNotEmpty
                  ? const Center(child: Text('No chief complaints found.'))
                  : ListView.builder(
                      itemCount: _filteredCcs.length,
                      itemBuilder: (context, index) {
                        final cc = _filteredCcs[index];
                        return Card(
                          child: ListTile(
                            title: Text(cc.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCc(cc),
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
