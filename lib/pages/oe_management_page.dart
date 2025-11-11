import 'package:digital_prescription/database/database_helper.dart';
import 'package:digital_prescription/models/on_examination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class OeManagementPage extends StatefulWidget {
  const OeManagementPage({Key? key}) : super(key: key);

  @override
  State<OeManagementPage> createState() => _OeManagementPageState();
}

class _OeManagementPageState extends State<OeManagementPage> {
  List<OnExamination> _oes = [];
  List<OnExamination> _filteredOes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOes();
    _searchController.addListener(_filterOes);
  }

  Future<void> _loadOes() async {
    final oes = await DatabaseHelper().getOnExaminations(limit: 20);
    if (mounted) {
      setState(() {
        _oes = oes;
        _filterOes();
      });
    }
  }

  void _filterOes() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      // Show only first 20 items when no search query
      setState(() {
        _filteredOes = _oes;
      });
    } else {
      // Show all matching items when searching
      _loadAllOesForSearch();
    }
  }

  Future<void> _loadAllOesForSearch() async {
    final allOes = await DatabaseHelper().getAllOnExaminations();
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOes = allOes
          .where((oe) => oe.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _deleteOe(OnExamination oe) async {
    if (oe.id != null) {
      await DatabaseHelper().deleteOnExamination(oe.id!);
      _loadOes(); // Refresh the list
    }
  }

  Future<void> _addOe(String name) async {
    if (name.isNotEmpty) {
      final newOe = OnExamination(name: name);
      await DatabaseHelper().insertOnExamination(newOe);
      _searchController.clear();
      _loadOes();
    }
  }

  void _showAddOeDialog() {
    final TextEditingController addOeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New On Examination'),
          content: TextField(
            controller: addOeController,
            decoration: const InputDecoration(hintText: "Enter on examination"),
            autofocus: true,
            onSubmitted: (value) {
              _addOe(value);
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
                _addOe(addOeController.text);
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
    _searchController.removeListener(_filterOes);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('On Examination Management')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TypeAheadField<OnExamination>(
                    hideOnEmpty: true,
                    suggestionsCallback: (pattern) async {
                      if (pattern.isEmpty) {
                        return [];
                      }
                      return _oes
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
                          labelText: 'Search On Examination',
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
                  onPressed: _showAddOeDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Add O/E'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredOes.isEmpty && _searchController.text.isNotEmpty
                  ? const Center(
                      child: Text('No on examination entries found.'),
                    )
                  : ListView.builder(
                      itemCount: _filteredOes.length,
                      itemBuilder: (context, index) {
                        final oe = _filteredOes[index];
                        return Card(
                          child: ListTile(
                            title: Text(oe.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteOe(oe),
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
