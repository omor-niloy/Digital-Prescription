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
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      // Use regular sqflite for mobile platforms
      path = join(await getDatabasesPath(), 'medicines.db');
      return await openDatabase(
        path,
        version: 2,
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
    await _seedDatabase(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Clear existing medicines and reseed with updated list
      await db.delete('medicines');
      await _seedDatabase(db);
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
}
