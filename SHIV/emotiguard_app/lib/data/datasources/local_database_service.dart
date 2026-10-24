import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/utils/crypto_vault.dart';
import '../../domain/entities/sensor_packet.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/baseline_profile.dart';

class LocalDatabaseService {
  static Database? _db;
  final CryptoVault _vault;

  LocalDatabaseService({CryptoVault? vault}) : _vault = vault ?? CryptoVault();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'emotiguard_secure.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table for encrypted sensor readings
        await db.execute('''
          CREATE TABLE sensor_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            encrypted_payload TEXT NOT NULL,
            heart_rate REAL NOT NULL,
            eda REAL NOT NULL,
            movement REAL NOT NULL
          )
        ''');

        // Table for encrypted reflections/journals
        await db.execute('''
          CREATE TABLE journal_reflections (
            id TEXT PRIMARY KEY,
            timestamp INTEGER NOT NULL,
            mood_score INTEGER NOT NULL,
            encrypted_content TEXT NOT NULL,
            distress_score REAL
          )
        ''');

        // Table for baseline metrics
        await db.execute('''
          CREATE TABLE user_baseline (
            id INTEGER PRIMARY KEY,
            updated_at INTEGER NOT NULL,
            json_data TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> saveSensorPacket(SensorPacket packet) async {
    final db = await database;
    final jsonStr = jsonEncode(packet.toJson());
    final encrypted = _vault.encrypt(jsonStr);

    await db.insert(
      'sensor_readings',
      {
        'timestamp': packet.timestamp,
        'encrypted_payload': encrypted,
        'heart_rate': packet.heartRate,
        'eda': packet.eda,
        'movement': packet.movementMagnitude,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SensorPacket>> getRecentHistory({Duration duration = const Duration(hours: 24)}) async {
    final db = await database;
    final cutoff = (DateTime.now().subtract(duration).millisecondsSinceEpoch ~/ 1000);

    final rows = await db.query(
      'sensor_readings',
      where: 'timestamp >= ?',
      whereArgs: [cutoff],
      orderBy: 'timestamp ASC',
    );

    return rows.map((r) {
      final encrypted = r['encrypted_payload'] as String;
      final decrypted = _vault.decrypt(encrypted);
      try {
        return SensorPacket.fromJson(jsonDecode(decrypted));
      } catch (_) {
        return SensorPacket(
          timestamp: r['timestamp'] as int,
          heartRate: (r['heart_rate'] as num).toDouble(),
          hrv: 50.0,
          eda: (r['eda'] as num).toDouble(),
          accelX: 0.0,
          accelY: 0.0,
          accelZ: 1.0,
        );
      }
    }).toList();
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    final db = await database;
    final payload = jsonEncode({
      'prompt': entry.prompt,
      'content': entry.content,
      'tags': entry.tags,
    });
    final encrypted = _vault.encrypt(payload);

    await db.insert(
      'journal_reflections',
      {
        'id': entry.id,
        'timestamp': entry.timestamp.millisecondsSinceEpoch ~/ 1000,
        'mood_score': entry.moodScore,
        'encrypted_content': encrypted,
        'distress_score': entry.associatedDistressScore,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<JournalEntry>> getJournalEntries() async {
    final db = await database;
    final rows = await db.query('journal_reflections', orderBy: 'timestamp DESC');

    return rows.map((r) {
      final decrypted = _vault.decrypt(r['encrypted_content'] as String);
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(decrypted);
      } catch (_) {}

      return JournalEntry(
        id: r['id'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch((r['timestamp'] as int) * 1000),
        moodScore: r['mood_score'] as int,
        prompt: body['prompt'] as String? ?? 'Reflection',
        content: body['content'] as String? ?? '',
        associatedDistressScore: (r['distress_score'] as num?)?.toDouble(),
        tags: (body['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
    }).toList();
  }

  /// Privacy-First: Permanently deletes all encrypted biometric and journal data
  Future<void> deleteAllUserData() async {
    final db = await database;
    await db.delete('sensor_readings');
    await db.delete('journal_reflections');
    await db.delete('user_baseline');
  }

  /// Exports unencrypted CSV format for user portability
  Future<String> exportCsv() async {
    final history = await getRecentHistory(duration: const Duration(days: 30));
    final buffer = StringBuffer();
    buffer.writeln('timestamp,iso_time,heart_rate_bpm,hrv_ms,eda_uS,accel_x,accel_y,accel_z,movement_magnitude');

    for (final p in history) {
      final iso = DateTime.fromMillisecondsSinceEpoch(p.timestamp * 1000).toIso8601String();
      buffer.writeln('${p.timestamp},$iso,${p.heartRate},${p.hrv},${p.eda},${p.accelX},${p.accelY},${p.accelZ},${p.movementMagnitude.toStringAsFixed(3)}');
    }

    return buffer.toString();
  }
}
