import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:elimupepe/models/ebook.dart';

class DatabaseService {
  static const String _dbName = 'ebook_reader.db';
  static const int _dbVersion = 3; // Incremented for schema change
  static const String _ebooksTable = 'ebooks';

  Database? _database;
  static final DatabaseService _instance = DatabaseService._();

  DatabaseService._();

  factory DatabaseService() {
    return _instance;
  }

  static DatabaseService get instance => _instance;

  // Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await _createTables(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Add grade column to existing table
          await db.execute(
            'ALTER TABLE $_ebooksTable ADD COLUMN grade TEXT NOT NULL DEFAULT "1"',
          );
        }
        if (oldVersion < 3) {
          // Add category and coverImagePath columns
          try {
            await db.execute(
              'ALTER TABLE $_ebooksTable ADD COLUMN category TEXT NOT NULL DEFAULT "Textbooks"',
            );
          } catch (e) {
            // Column might already exist
          }
          try {
            await db.execute(
              'ALTER TABLE $_ebooksTable ADD COLUMN coverImagePath TEXT',
            );
          } catch (e) {
            // Column might already exist
          }
        }
      },
    );
  }

  // Create database tables
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_ebooksTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        description TEXT,
        coverUrl TEXT,
        localPath TEXT,
        totalPages INTEGER NOT NULL,
        downloadedDate TEXT NOT NULL,
        isDownloaded INTEGER NOT NULL,
        fileSize INTEGER NOT NULL,
        serverUrl TEXT,
        grade TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT "Textbooks",
        coverImagePath TEXT
      )
    ''');
  }

  // Add or update ebook
  Future<void> insertEbook(Ebook ebook) async {
    final db = await database;
    await db.insert(
      _ebooksTable,
      ebook.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all ebooks
  Future<List<Ebook>> getAllEbooks() async {
    final db = await database;
    final maps = await db.query(_ebooksTable);
    return maps.map((map) => Ebook.fromJson(map)).toList();
  }

  // Get ebook by ID
  Future<Ebook?> getEbookById(String id) async {
    final db = await database;
    final maps = await db.query(_ebooksTable, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Ebook.fromJson(maps.first);
  }

  // Get downloaded ebooks only
  Future<List<Ebook>> getDownloadedEbooks() async {
    final db = await database;
    final maps = await db.query(
      _ebooksTable,
      where: 'isDownloaded = ?',
      whereArgs: [1],
    );
    return maps.map((map) => Ebook.fromJson(map)).toList();
  }

  // Delete ebook record
  Future<void> deleteEbook(String id) async {
    final db = await database;
    await db.delete(_ebooksTable, where: 'id = ?', whereArgs: [id]);
  }

  // Update ebook
  Future<void> updateEbook(Ebook ebook) async {
    final db = await database;
    await db.update(
      _ebooksTable,
      ebook.toJson(),
      where: 'id = ?',
      whereArgs: [ebook.id],
    );
  }

  // Add bundled ebook to database
  Future<void> addBundledEbook(Ebook ebook) async {
    final db = await database;
    await db.insert(
      _ebooksTable,
      ebook.toJson(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Close database
  Future<void> closeDatabase() async {
    await _database?.close();
    _database = null;
  }
}
