import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelperPunchIn {
  static final DatabaseHelperPunchIn _instance =
      DatabaseHelperPunchIn._internal();

  factory DatabaseHelperPunchIn() => _instance;

  static Database? _database;

  DatabaseHelperPunchIn._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'punch_data.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // await db.execute('''
    //   CREATE TABLE punch_entries (
    //     id INTEGER PRIMARY KEY AUTOINCREMENT,
    //     transaction_date TEXT,
    //     transaction_time TEXT,
    //     staff_code TEXT,
    //     flag_value TEXT,
    //     address TEXT,
    //     latitude TEXT,
    //     longitude TEXT
    //   )
    // ''');

    await db.execute('''
  CREATE TABLE punch_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transaction_date TEXT,
    transaction_time TEXT,
    staff_code TEXT,
    flag_value TEXT,
    address TEXT,
    latitude TEXT,
    longitude TEXT,
    UNIQUE(staff_code, flag_value) ON CONFLICT REPLACE
  )
''');
  }

  Future<bool> checkDuplicateEntry(
      String staffCode, String date, String flagValue) async {
    final db = await database;
    final result = await db.query(
      'punch_entries',
      where: 'staff_code = ? AND transaction_date = ? AND flag_value = ?',
      whereArgs: [staffCode, date, flagValue],
    );
    return result.isNotEmpty;
  }

  // Future<bool> checkDuplicatePunchOut(String staffCode, String date, String flagValue) async {
  //   final db = await database;
  //
  //   // Check if the last punch was also a punch-out
  //   final List<Map<String, dynamic>> result = await db.query(
  //     'punch_entries',
  //     where: 'staff_code = ? AND transaction_date = ? AND flag_value = ?',
  //     whereArgs: [staffCode, date, flagValue],
  //     orderBy: 'id DESC',
  //     limit: 1,
  //   );
  //
  //   return result.isNotEmpty;
  // }

  Future<List<Map<String, dynamic>>> getOfflinePunchEntries() async {
    final db = await database;
    return await db.query('punch_entries');
  }

  Future<int> insertPunchEntry(Map<String, dynamic> data) async {
    final db = await database;
    print("Inserting into DB: $data");
    return await db.insert('punch_entries', data);
  }

  Future<int> deletePunchEntry(int id) async {
    final db = await database;
    return await db.delete('punch_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getLastPunchEntry(String staffCode) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'punch_entries',
      where: 'staff_code = ?',
      whereArgs: [staffCode],
      orderBy: 'id DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Optional: Get all entries
  Future<List<Map<String, dynamic>>> getAllEntries() async {
    final db = await database;
    return await db.query('punch_entries');
  }
}
