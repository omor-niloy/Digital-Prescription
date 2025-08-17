import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'controllers/prescription_controller.dart';
import 'widgets/home_drawer.dart';
import 'widgets/patient_info_panel.dart';
import 'widgets/prescription_page.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const PrescriptionApp());
}

class PrescriptionApp extends StatelessWidget {
  const PrescriptionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Prescription',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[200],
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PrescriptionController _prescriptionController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _prescriptionController = PrescriptionController();
    _prescriptionController.setOnUpdate(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Prescription'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: () {
                _prescriptionController.clearAll();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: () {
                // Add print functionality here
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.print),
              label: const Text('Print'),
            ),
          ),
        ],
      ),
      drawer: const HomeDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Define a breakpoint for switching between layouts
          const double wideLayoutBreakpoint = 1200;

          if (constraints.maxWidth > wideLayoutBreakpoint) {
            // WIDE LAYOUT: Side-by-side panel and pages
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Info Panel (takes 30% of available width)
                Expanded(
                  flex: 3,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 350,
                      maxWidth: 500,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: PatientInfoPanel(
                          controller: _prescriptionController,
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                // Prescription Pages (takes 70% of available width)
                Expanded(
                  flex: 7,
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 40,
                        ),
                        child: Column(
                          children: [
                            for (
                              int i = 0;
                              i < _prescriptionController.pages.length;
                              i++
                            )
                              PrescriptionPage(
                                pageIndex: i,
                                pageModel: _prescriptionController.pages[i],
                                controller: _prescriptionController,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // NARROW LAYOUT: Panel on top of pages
            return InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          child: PatientInfoPanel(
                            controller: _prescriptionController,
                          ),
                        ),
                      ),
                      const Divider(),
                      for (
                        int i = 0;
                        i < _prescriptionController.pages.length;
                        i++
                      )
                        PrescriptionPage(
                          pageIndex: i,
                          pageModel: _prescriptionController.pages[i],
                          controller: _prescriptionController,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
