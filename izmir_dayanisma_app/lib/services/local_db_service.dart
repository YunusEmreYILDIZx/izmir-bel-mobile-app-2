// lib/services/local_db_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';

class LocalDbService {
  static Database? _database;

  /// Uygulama başlarken tekil instance almak için
  static Future<LocalDbService> getInstance() async {
    final service = LocalDbService();
    await service._initDb();
    return service;
  }

  Future<void> _initDb() async {
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      join(dbPath, 'dayanisma.db'),
      version: 4, // versiyon 4’e yükseltildi
      onCreate: (db, version) async {
        // 1) users tablosu (role sütunu ile)
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            role TEXT DEFAULT 'user'
          )
        ''');
        // ← Bunu ekleyin:
        await db.insert('users', {
          'name': 'Admin',
          'email': 'admin@admin.com',
          'password': 'emre123', // dilediğiniz güvenli şifreyi koyun
          'role': 'admin',
        });

        // 2) events tablosu
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            date TEXT,
            location TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 → v2: events tablosunu ekle
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              description TEXT,
              date TEXT,
              location TEXT
            )
          ''');
        }
        // v2 → v3: users tablosuna role sütunu ekle
        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE users
            ADD COLUMN role TEXT DEFAULT 'user'
          ''');
        }
        // v3 → v4: ilerdeki migration’lar için yer
        if (oldVersion < 4) {
          // (Buraya ek migration kodları gelebilir)
        }
      },
    );
  }

  Database get db {
    if (_database == null) {
      throw Exception('Database not initialized!');
    }
    return _database!;
  }

  /// Yeni bir etkinlik ekle
  Future<int> insertEvent(Event event) async {
    return await db.insert('events', event.toMap());
  }

  /// Tüm etkinlikleri getir
  Future<List<Event>> getAllEvents() async {
    final maps = await db.query('events', orderBy: 'date DESC');
    return maps.map((m) => Event.fromMap(m)).toList();
  }

  /// Bir etkinliği güncelle
  Future<int> updateEvent(Event event) async {
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// Bir etkinliği sil
  Future<int> deleteEvent(int id) async {
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}
