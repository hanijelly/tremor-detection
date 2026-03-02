import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tremor_event.dart';

class AccelerometerReading {
  final int? id;
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
  final double magnitude;

  AccelerometerReading({
    this.id,
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
    required this.magnitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'z': z,
      'timestamp': timestamp.toIso8601String(),
      'magnitude': magnitude,
    };
  }

  factory AccelerometerReading.fromMap(Map<String, dynamic> map) {
    return AccelerometerReading(
      id: map['id'],
      x: map['x'],
      y: map['y'],
      z: map['z'],
      timestamp: DateTime.parse(map['timestamp']),
      magnitude: map['magnitude'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tremor_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Existing readings table
    await db.execute('''
      CREATE TABLE readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x REAL NOT NULL,
        y REAL NOT NULL,
        z REAL NOT NULL,
        timestamp TEXT NOT NULL,
        magnitude REAL NOT NULL
      )
    ''');
    
    // New tremor events table
    await db.execute('''
      CREATE TABLE tremor_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        magnitude REAL NOT NULL,
        duration REAL NOT NULL,
        severity TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertReading(AccelerometerReading reading) async {
    final db = await database;
    return await db.insert('readings', reading.toMap());
  }

  Future<List<AccelerometerReading>> getAllReadings() async {
    final db = await database;
    final result = await db.query(
      'readings',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => AccelerometerReading.fromMap(map)).toList();
  }

  Future<List<AccelerometerReading>> getRecentReadings(int limit) async {
    final db = await database;
    final result = await db.query(
      'readings',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return result.map((map) => AccelerometerReading.fromMap(map)).toList();
  }

  Future<List<AccelerometerReading>> getReadingsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.query(
      'readings',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
    return result.map((map) => AccelerometerReading.fromMap(map)).toList();
  }

  Future<int> deleteAllReadings() async {
    final db = await database;
    return await db.delete('readings');
  }
  Future<int> insertTremorEvent(TremorEvent event) async {
    final db = await database;
    return await db.insert('tremor_events', event.toMap());
  }

  Future<List<TremorEvent>> getAllTremorEvents() async {
    final db = await database;
    final result = await db.query(
      'tremor_events',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => TremorEvent.fromMap(map)).toList();
  }

  Future<int> deleteAllTremorEvents() async {
    final db = await database;
    return await db.delete('tremor_events');
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}