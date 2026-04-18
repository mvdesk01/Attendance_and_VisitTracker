import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const int databaseVersion = 3; //  Increment version when schema changes

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
    print("✅ Table 'locations' created with all required columns.");
  }
  // Future<void> markAsSynced(String timestamp, double lat, double lng) async {
  //   final db = await database;
  //   await db.update(
  //     'locations',
  //     {'synced': 1},
  //     where: 'timestamp = ? AND latitude = ? AND longitude = ?',
  //     whereArgs: [timestamp, lat, lng],
  //   );
  // }

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
  Future<void> _upgradeTable(Database db, int oldVersion, int newVersion) async {
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
//   Future<int> insertLocation(Map<String, dynamic> location) async {
//     final db = await database;
//     return await db.insert('locations', {
//       ...location,
//       'epochMillis': DateTime.now().millisecondsSinceEpoch,
//       'synced': 0,
//     });
//   }

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
}




/*class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'location_data.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) {
        return db.execute(
          '''CREATE TABLE locations (
              latitude REAL,
              longitude REAL,
              address TEXT,
              speed REAL,
              distanceInMeters REAL,
              distanceInKm REAL,
              srNo_Vo TEXT,
              timestamp TEXT
          )''',
        );
      },
    );
  }

  Future<void> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    await db.insert('locations', location);
  }

  Future<List<Map<String, dynamic>>> getStoredLocations() async {
    final db = await database;
    return await db.query('locations');
  }

  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }
}*/


/*
class DatabaseHelper {
  static Database? _database;
  static const int databaseVersion = 4; //  Increment version when schema changes

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
        _createTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) {
        _dropAndRecreateTable(db);
      },
    );
  }

  ///  **Drop the old table and create a new one**
  Future<void> _dropAndRecreateTable(Database db) async {
    print("⚠️ Dropping old table and creating a new one...");
    await db.execute("DROP TABLE IF EXISTS locations");
    await _createTable(db);
    print(" New table created successfully.");
  }

  ///  **Create the new table with all required parameters**
  Future<void> _createTable(Database db) async {
    await db.execute(
      '''CREATE TABLE locations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transactionId TEXT,
          transactionDate TEXT,
          transactionTime TEXT,
          latitude REAL,
          longitude REAL,
          staffcode TEXT,
          deviceId TEXT,
          uuidid TEXT,
          process TEXT,
          actualDate TEXT,
          actualTime TEXT,
          address TEXT,
          speed REAL,
          distance REAL,
          srNo_Vo TEXT,
          status TEXT,
          distanceInKm REAL,
          gpsCheckFlag TEXT
      )''',
    );
    print(" Table created successfully.");
  }

  Future<void> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    await db.insert('locations', location);
    print("📌 Data inserted into SQLite: $location");
  }

  Future<List<Map<String, dynamic>>> getStoredLocations() async {
    final db = await database;
    return await db.query('locations');
  }

  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
    print("🗑️ Data with ID $id deleted from SQLite.");
  }

  /// ✅ **Force database reset (Use only for debugging)**
  Future<void> resetDatabase() async {
    final db = await database;
    await db.execute("DROP TABLE IF EXISTS locations");
    await _createTable(db);
    print("⚠️ Database reset! Table recreated.");
  }
}
*/
