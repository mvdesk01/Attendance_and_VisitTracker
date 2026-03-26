import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelperPunchout {
  static final DatabaseHelperPunchout _instance = DatabaseHelperPunchout._internal();
  factory DatabaseHelperPunchout() => _instance;

  static Database? _database;

  DatabaseHelperPunchout._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'punchout_data.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE punchout_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_date TEXT,
        transaction_time TEXT,
        staff_code TEXT,
        flag_value TEXT,
        address TEXT,
        latitude TEXT,
        longitude TEXT,
        UNIQUE(staff_code, transaction_date, flag_value) ON CONFLICT REPLACE
      )
    ''');
  }

  Future<bool> checkDuplicatePunchOut(String staffCode, String date, String flagValue) async {
    final db = await database;
    final result = await db.query(
      'punchout_entries',
      where: 'staff_code = ? AND transaction_date = ? AND flag_value = ?',
      whereArgs: [staffCode, date, flagValue],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getOfflinePunchoutEntries() async {
    final db = await database;
    return await db.query('punchout_entries');
  }

  Future<int> insertPunchoutEntry(Map<String, dynamic> data) async {
    final db = await database;
    print("Inserting into DB: $data");
    return await db.insert('punchout_entries', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deletePunchoutEntry(int id) async {
    final db = await database;
    return await db.delete('punchout_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getLastPunchoutEntry(String staffCode) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'punchout_entries',
      where: 'staff_code = ?',
      whereArgs: [staffCode],
      orderBy: 'id DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllEntries() async {
    final db = await database;
    return await db.query('punchout_entries');
  }
}