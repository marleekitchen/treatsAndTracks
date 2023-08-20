import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final _dbName = 'petReminderDb.db';
  static final _dbVersion = 1;

  static final tablePets = 'pets';
  static final columnPetId = 'id';
  static final columnPetName = 'name';
  static final columnPetAge = 'age';

  static final tableTasks = 'tasks';
  static final columnTaskId = 'id';
  static final columnTaskName = 'name';
  static final columnTaskDescription = 'description';
  static final columnIsDaily = 'isDaily';
  static final columnDate = 'date';
  static final columnTime = 'time';
  static final columnPetFK = 'petId';

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Database instance
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  // Insert
  Future<int> insert(Map<String, dynamic> row, String tableName) async {
    Database db = await instance.database;
    return await db.insert(tableName, row);
  }

// Query
  Future<List<Map<String, dynamic>>> queryAll(String tableName) async {
    Database db = await instance.database;
    return await db.query(tableName);
  }

  // Query a specific row based on ID
  Future<List<Map<String, dynamic>>> querySpecific(
      String tableName, int id) async {
    Database db = await instance.database;
    return await db.query(tableName, where: 'id = ?', whereArgs: [id]);
  }

// Delete
  Future<int> delete(int id, String tableName, String columnName) async {
    Database db = await instance.database;
    return await db
        .delete(tableName, where: '$columnName = ?', whereArgs: [id]);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePets (
        $columnPetId INTEGER PRIMARY KEY,
        $columnPetName TEXT NOT NULL,
        $columnPetAge INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableTasks (
        $columnTaskId INTEGER PRIMARY KEY,
        $columnTaskName TEXT NOT NULL,
        $columnTaskDescription TEXT,
        $columnIsDaily INTEGER NOT NULL,
        $columnDate TEXT,
        $columnTime TEXT,
        $columnPetFK INTEGER,
        FOREIGN KEY ($columnPetFK) REFERENCES $tablePets ($columnPetId)
      )
    ''');
  }
}
