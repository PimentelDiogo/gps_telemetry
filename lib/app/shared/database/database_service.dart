import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:gps_telemetry/app/shared/models/telemetry_data.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'gps_telemetry.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE telemetry_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        total_distance REAL DEFAULT 0,
        max_speed REAL DEFAULT 0,
        avg_speed REAL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE telemetry_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL,
        speed REAL,
        heading REAL,
        acceleration_x REAL,
        acceleration_y REAL,
        acceleration_z REAL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES telemetry_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_telemetry_points_session_id ON telemetry_points(session_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_telemetry_points_timestamp ON telemetry_points(timestamp)
    ''');
  }

  // Sessões de telemetria
  Future<int> createSession(String name) async {
    final db = await database;
    return await db.insert('telemetry_sessions', {
      'name': name,
      'start_time': DateTime.now().millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> endSession(int sessionId, {
    double? totalDistance,
    double? maxSpeed,
    double? avgSpeed,
  }) async {
    final db = await database;
    await db.update(
      'telemetry_sessions',
      {
        'end_time': DateTime.now().millisecondsSinceEpoch,
        if (totalDistance != null) 'total_distance': totalDistance,
        if (maxSpeed != null) 'max_speed': maxSpeed,
        if (avgSpeed != null) 'avg_speed': avgSpeed,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await database;
    return await db.query(
      'telemetry_sessions',
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getSession(int sessionId) async {
    final db = await database;
    final results = await db.query(
      'telemetry_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Pontos de telemetria
  Future<int> insertTelemetryPoint(TelemetryData data) async {
    final db = await database;
    return await db.insert('telemetry_points', data.toMap());
  }

  Future<List<TelemetryData>> getSessionPoints(int sessionId) async {
    final db = await database;
    final results = await db.query(
      'telemetry_points',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return results.map((map) => TelemetryData.fromMap(map)).toList();
  }

  Future<List<TelemetryData>> getPointsInTimeRange(
    int sessionId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final results = await db.query(
      'telemetry_points',
      where: 'session_id = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [
        sessionId,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp ASC',
    );
    return results.map((map) => TelemetryData.fromMap(map)).toList();
  }

  // Estatísticas
  Future<Map<String, dynamic>> getSessionStatistics(int sessionId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as point_count,
        MAX(speed) as max_speed,
        AVG(speed) as avg_speed,
        MIN(timestamp) as start_time,
        MAX(timestamp) as end_time
      FROM telemetry_points 
      WHERE session_id = ?
    ''', [sessionId]);

    return result.isNotEmpty ? result.first : {};
  }

  // Limpeza
  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    await db.delete(
      'telemetry_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> clearOldSessions({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .millisecondsSinceEpoch;

    await db.delete(
      'telemetry_sessions',
      where: 'created_at < ?',
      whereArgs: [cutoffTime],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}