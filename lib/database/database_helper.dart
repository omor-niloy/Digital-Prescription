import 'package:digital_prescription/models/chief_complaint.dart';
import 'package:digital_prescription/models/on_examination.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:digital_prescription/models/medicine.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Use FFI database factory for desktop platforms
      path = join(await databaseFactoryFfi.getDatabasesPath(), 'medicines.db');
      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      // Use regular sqflite for mobile platforms
      path = join(await getDatabasesPath(), 'medicines.db');
      return await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE chief_complaints(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE on_examinations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await _seedDatabase(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Clear existing medicines and reseed with updated list
      await db.delete('medicines');
      await _seedDatabase(db);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE chief_complaints(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE on_examinations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');
      await _seedNewTables(db);
    }
  }

  Future<List<Medicine>> getMedicines({int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return Medicine.fromMap(maps[i]);
    });
  }

  Future<List<Medicine>> getAllMedicines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('medicines');
    return List.generate(maps.length, (i) {
      return Medicine.fromMap(maps[i]);
    });
  }

  Future<void> deleteMedicine(int id) async {
    final db = await database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertMedicine(Medicine medicine) async {
    final db = await database;
    await db.insert(
      'medicines',
      medicine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _seedDatabase(Database db) async {
    await _seedMedicines(db);
    await _seedNewTables(db);
  }

  Future<void> _seedMedicines(Database db) async {
    try {
      // Load medicines from the text file
      final String medicineData = await rootBundle.loadString(
        'assets/data/medicines.txt',
      );
      final List<String> initialMedicines = medicineData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      Batch batch = db.batch();
      for (String name in initialMedicines) {
        batch.insert('medicines', {'name': name});
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Fallback to default medicines if file reading fails
      List<String> fallbackMedicines = ['Napa', 'Paracetamol'];
      Batch batch = db.batch();
      for (String name in fallbackMedicines) {
        batch.insert('medicines', {'name': name});
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _seedNewTables(Database db) async {
    List<String> initialCCs = ['Fever', 'Cough', 'Headache', 'Abdominal Pain', 'Vomiting'];
    Batch ccBatch = db.batch();
    for (String name in initialCCs) {
      ccBatch.insert('chief_complaints', {'name': name});
    }
    await ccBatch.commit(noResult: true);

    List<String> initialOEs = ['NAD (No Abnormality Detected)', 'Tenderness in abdomen', 'Chest clear', 'BP: 120/80 mmHg', 'Temp: 98.6 F'];
    Batch oeBatch = db.batch();
    for (String name in initialOEs) {
      oeBatch.insert('on_examinations', {'name': name});
    }
    await oeBatch.commit(noResult: true);
  }

  Future<List<Medicine>> searchMedicines(String query) async {
    final db = await database;
    if (query.isEmpty) {
      return [];
    }
    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      limit: 5,
    );
    return List.generate(maps.length, (i) {
      return Medicine.fromMap(maps[i]);
    });
  }

  // Chief Complaint Methods
  Future<List<ChiefComplaint>> getChiefComplaints({int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chief_complaints',
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return ChiefComplaint.fromMap(maps[i]);
    });
  }

  Future<List<ChiefComplaint>> getAllChiefComplaints() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('chief_complaints');
    return List.generate(maps.length, (i) {
      return ChiefComplaint.fromMap(maps[i]);
    });
  }

  Future<void> deleteChiefComplaint(int id) async {
    final db = await database;
    await db.delete('chief_complaints', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertChiefComplaint(ChiefComplaint cc) async {
    final db = await database;
    await db.insert(
      'chief_complaints',
      cc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChiefComplaint>> searchChiefComplaints(String query) async {
    final db = await database;
    if (query.isEmpty) {
      return [];
    }
    final List<Map<String, dynamic>> maps = await db.query(
      'chief_complaints',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      limit: 5,
    );
    return List.generate(maps.length, (i) {
      return ChiefComplaint.fromMap(maps[i]);
    });
  }

  // On Examination Methods
  Future<List<OnExamination>> getOnExaminations({int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'on_examinations',
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return OnExamination.fromMap(maps[i]);
    });
  }

  Future<List<OnExamination>> getAllOnExaminations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('on_examinations');
    return List.generate(maps.length, (i) {
      return OnExamination.fromMap(maps[i]);
    });
  }

  Future<void> deleteOnExamination(int id) async {
    final db = await database;
    await db.delete('on_examinations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertOnExamination(OnExamination oe) async {
    final db = await database;
    await db.insert(
      'on_examinations',
      oe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OnExamination>> searchOnExaminations(String query) async {
    final db = await database;
    if (query.isEmpty) {
      return [];
    }
    final List<Map<String, dynamic>> maps = await db.query(
      'on_examinations',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      limit: 5,
    );
    return List.generate(maps.length, (i) {
      return OnExamination.fromMap(maps[i]);
    });
  }
}