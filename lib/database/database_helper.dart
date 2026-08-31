import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;
  static const int databaseVersion =
      4; //  Increment version when schema changes

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'location_data.db');
    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: (db, version) {
        return _createTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute("DROP TABLE IF EXISTS locations");
        await _createTable(db);
        print("⚠️ Database reset and recreated on upgrade.");
      },
    );
  }

  ///  **Create the table**
  Future<void> _createTable(Database db) async {
    await db.execute(
      '''CREATE TABLE locations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      latitude REAL, 
      longitude REAL, 
      address TEXT,
      speed REAL,
      distanceInMeters REAL,
      distanceInKm REAL,
      srNo_Vo TEXT,
      timestamp TEXT,
      datestamp TEXT,  -- ✅ Add this column
      staffcode TEXT,
      batteryPercentage TEXT,
      synced INTEGER DEFAULT 0
  )''',
    );

    await db.execute('''
  CREATE TABLE punch_state (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_code TEXT NOT NULL,
    transaction_date TEXT NOT NULL,
    transaction_time TEXT NOT NULL,
    flag_value TEXT NOT NULL,
    shift_date TEXT,
    shift_type TEXT
  )
''');
    print("✅ Table 'locations' created with all required columns.");
  }

  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'locations',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    print("✅ Location with ID $id marked as synced.");
  }

  ///  **Upgrade table when schema changes**
  Future<void> _upgradeTable(
      Database db, int oldVersion, int newVersion) async {
    print("🔄 Upgrading database from version $oldVersion to $newVersion...");

    if (oldVersion < 4) {
      await db.execute("ALTER TABLE locations ADD COLUMN staffcode TEXT");
      print(" 'staffcode' column added.");
    }
  }

  Future<void> batchStorage(Map<String, dynamic> position) async {
    final db = await database;
    await db.insert('batchStorage', position);
    print(" Data inserted into SQLite batch storage: $position");
  }

//
  Future<void> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    await db.insert('locations', location);
    print(" Data inserted into SQLite: $location");
  }

  Future<List<Map<String, dynamic>>> getStoredLocations() async {
    final db = await database;
    // return await db.query('locations');
    return await db.query(
      'locations',
      where: 'synced = 0',
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
    print("Data with ID $id deleted from SQLite.");
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.execute("DROP TABLE IF EXISTS locations");
    await _createTable(db);
    print(" Database reset! Table recreated.");
  }

  Future<void> insertPunchState({
    required String staffCode,
    required String transactionDate,
    required String transactionTime,
    required String flagValue,
    String? shiftDate,
    String? shiftType,
  }) async {
    final db = await database;

    await db.insert('punch_state', {
      'staff_code': staffCode,
      'transaction_date': transactionDate,
      'transaction_time': transactionTime,
      'flag_value': flagValue,
      'shift_date': shiftDate,
      'shift_type': shiftType,
    });

    print(
        "Punch state stored: $staffCode | $transactionDate | $transactionTime | $flagValue");
  }

  Future<Map<String, dynamic>?> getLatestPunchState(String staffCode) async {
    final db = await database;

    final result = await db.query(
      'punch_state',
      where: 'staff_code = ?',
      whereArgs: [staffCode],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  Future<Map<String, dynamic>?> getLatestPunchIn(String staffCode) async {
    final db = await database;

    final result = await db.query(
      'punch_state',
      where: 'staff_code = ? AND flag_value = ?',
      whereArgs: [staffCode, '001'],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  Future<Map<String, dynamic>?> getLatestPunchOut(String staffCode) async {
    final db = await database;

    final result = await db.query(
      'punch_state',
      where: 'staff_code = ? AND flag_value = ?',
      whereArgs: [staffCode, '000'],
      orderBy: 'id DESC',
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }
}
