import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:udg_cactus_app/models/observation_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase('main3.db');
    return _database!;
  }

  Future<Database> _initDatabase(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Observations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag TEXT,
        date DATE NOT NULL,
        latitude REAL,
        longitude REAL,
        address TEXT,
        image BLOB,
        zoom BLOB,
        pixelColor INTEGER
      )''');
  }

  Future<int> addObservation(Observation observation) async {
    final db = await instance.database;

    print("[+] Observation added!");

    return await db.insert("Observations", observation.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateObservation(Observation observation) async {
    final db = await instance.database;
    return await db.update("Observations", observation.toJson(),
        where: 'id = ?',
        whereArgs: [observation.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteObservation(Observation observation) async {
    final db = await instance.database;
    print("[+] Observation deleted.");
    return await db
        .delete("Observations", where: 'id = ?', whereArgs: [observation.id]);
  }

  Future<List<Observation>?> fetchAllObservation() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query("Observations");

    if (maps.isEmpty) {
      return null;
    }

    return List.generate(
        maps.length, (index) => Observation.fromJson(maps[index]));
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
