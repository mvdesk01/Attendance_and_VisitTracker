import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class MomDraftDBHelper {
  static Database? _database;

  static const String _dbName = 'mom_draft.db';
  static const String _tableName = 'mom_drafts';

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();

    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customerCode TEXT NOT NULL,
            customerName TEXT,
            updatedAt TEXT NOT NULL,
            draftData TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Save a new draft or update the existing draft
  static Future<int> saveDraft({
    required String customerCode,
    required String customerName,
    required Map<String, dynamic> draftData,
  }) async {
    final db = await database;

    final existing = await db.query(
      _tableName,
      where: 'customerCode = ?',
      whereArgs: [customerCode],
      limit: 1,
    );

    final data = {
      'customerCode': customerCode,
      'customerName': customerName,
      'updatedAt': DateTime.now().toIso8601String(),
      'draftData': jsonEncode(draftData),
    };

    if (existing.isNotEmpty) {
      await db.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );

      return existing.first['id'] as int;
    }

    return await db.insert(
      _tableName,
      data,
    );
  }

  /// Get draft for a particular customer
  static Future<Map<String, dynamic>?> getDraft({
    required String customerCode,
  }) async {
    final db = await database;

    final result = await db.query(
      _tableName,
      where: 'customerCode = ?',
      whereArgs: [customerCode],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;

    return {
      'id': row['id'],
      'customerCode': row['customerCode'],
      'customerName': row['customerName'],
      'updatedAt': row['updatedAt'],
      'draftData': jsonDecode(row['draftData'] as String),
    };
  }

  /// Get all saved drafts
  static Future<List<Map<String, dynamic>>> getAllDrafts() async {
    final db = await database;

    final result = await db.query(
      _tableName,
      orderBy: 'updatedAt DESC',
    );

    return result.map((row) {
      return {
        'id': row['id'],
        'customerCode': row['customerCode'],
        'customerName': row['customerName'],
        'updatedAt': row['updatedAt'],
        'draftData': jsonDecode(row['draftData'] as String),
      };
    }).toList();
  }

  /// Delete draft for a customer
  static Future<void> deleteDraft({
    required String customerCode,
  }) async {
    final db = await database;

    await db.delete(
      _tableName,
      where: 'customerCode = ?',
      whereArgs: [customerCode],
    );
  }

  /// Delete draft using ID
  static Future<void> deleteDraftById(int id) async {
    final db = await database;

    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all drafts
  static Future<void> deleteAllDrafts() async {
    final db = await database;

    await db.delete(_tableName);
  }

  static Future<void> close() async {
    final db = _database;

    if (db != null && db.isOpen) {
      await db.close();
    }

    _database = null;
  }
}
