import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'diagnoses.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diagnoses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        disease TEXT NOT NULL,
        date TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        confidence REAL,
        patientName TEXT,
        patientId TEXT,
        address TEXT,
        contactNumber TEXT,
        dateOfBirth TEXT,
        age TEXT,
        gender TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN confidence REAL');
        await db.execute('ALTER TABLE diagnoses ADD COLUMN patientName TEXT');
        await db.execute('ALTER TABLE diagnoses ADD COLUMN patientId TEXT');
        await db.execute('ALTER TABLE diagnoses ADD COLUMN address TEXT');
        await db.execute('ALTER TABLE diagnoses ADD COLUMN contactNumber TEXT');
        await db.execute('ALTER TABLE diagnoses ADD COLUMN dateOfBirth TEXT');
        await db.execute('ALTER TABLE diagnoses ADD COLUMN age TEXT');
        await db.execute('ALTER TABLE diagnoses ADD COLUMN gender TEXT');
      } catch (e) {
        print("Database upgrade error: $e");
      }
    }
  }

  /// Returns only the last 10 diagnoses
  Future<List<Map<String, dynamic>>> getDiagnoses() async {
    final db = await database;
    // Strictly limit to 10 for "Recent Results"
    return await db.query('diagnoses', orderBy: 'id DESC', limit: 10);
  }

  Future<void> ensureSchemaUpdated() async {
    final db = await database;
    try {
      var columns = await db.rawQuery('PRAGMA table_info(diagnoses)');
      if (!columns.any((column) => column['name'] == 'confidence')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN confidence REAL');
      }
      if (!columns.any((column) => column['name'] == 'patientName')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN patientName TEXT');
      }
      if (!columns.any((column) => column['name'] == 'patientId')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN patientId TEXT');
      }
      if (!columns.any((column) => column['name'] == 'address')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN address TEXT');
      }
      if (!columns.any((column) => column['name'] == 'contactNumber')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN contactNumber TEXT');
      }
      if (!columns.any((column) => column['name'] == 'dateOfBirth')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN dateOfBirth TEXT');
      }
      if (!columns.any((column) => column['name'] == 'age')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN age TEXT');
      }
      if (!columns.any((column) => column['name'] == 'gender')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN gender TEXT');
      }
    } catch (e) {
      print("Error ensuring schema updated: $e");
    }
  }

  /// Inserts a new diagnosis and automatically deletes the oldest if count > 10
  Future<int> insertDiagnosis(
    String disease, 
    String imagePath, 
    double confidence, {
    String? patientName, 
    String? patientId,
    String? address,
    String? contactNumber,
    String? dateOfBirth,
    String? age,
    String? gender,
  }) async {
    final db = await database;
    await ensureSchemaUpdated();

    // AUTO-DELETE LOGIC: Maintain only 10 most recent entries
    final List<Map<String, dynamic>> currentEntries = await db.query('diagnoses', orderBy: 'id DESC');
    
    if (currentEntries.length >= 10) {
      // Get all IDs except the 9 most recent ones to be safe
      // but strictly we delete anything beyond the 9th to make room for the 10th
      final idsToDelete = currentEntries.sublist(9).map((e) => e['id']).toList();
      
      for (var id in idsToDelete) {
        final entry = currentEntries.firstWhere((e) => e['id'] == id);
        String? oldPath = entry['imagePath'];
        if (oldPath != null && oldPath.isNotEmpty) {
          try {
            final file = File(oldPath);
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
        await db.delete('diagnoses', where: 'id = ?', whereArgs: [id]);
      }
      print("Auto-deleted ${idsToDelete.length} old entries to maintain 10-limit.");
    }

    return await db.insert(
      'diagnoses',
      {
        'disease': disease,
        'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()), // Using standard format for sorting
        'imagePath': imagePath,
        'confidence': confidence,
        'patientName': patientName,
        'patientId': patientId,
        'address': address,
        'contactNumber': contactNumber,
        'dateOfBirth': dateOfBirth,
        'age': age,
        'gender': gender,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> saveImage(File image) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    String path = join(documentsDirectory.path, fileName);
    await image.copy(path);
    return path;
  }

  Future<void> deleteDiagnosis(int id) async {
    final db = await database;
    await db.delete('diagnoses', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all unique patients with their latest diagnosis record
  Future<List<Map<String, dynamic>>> getPastPatients() async {
    final db = await database;
    // Get unique patients with their latest record
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT DISTINCT patientId, patientName, disease, date, confidence
      FROM diagnoses
      WHERE patientId IS NOT NULL AND patientName IS NOT NULL
      ORDER BY date DESC
    ''');
    return results;
  }

  /// Ensure doctor credentials table exists
  Future<void> ensureDoctorTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS doctors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        licenseNumber TEXT NOT NULL,
        clinicLocation TEXT
      )
    ''');
    try {
      var columns = await db.rawQuery('PRAGMA table_info(doctors)');
      if (!columns.any((column) => column['name'] == 'clinicLocation')) {
        await db.execute('ALTER TABLE doctors ADD COLUMN clinicLocation TEXT');
      }
    } catch (_) {}
  }

  /// Register a doctor locally
  Future<bool> registerDoctor({
    required String fullName,
    required String email,
    required String username,
    required String password,
    required String licenseNumber,
    required String clinicLocation,
  }) async {
    final db = await database;
    await ensureDoctorTable();

    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim().toLowerCase();

    // Check if username or email already exists
    final List<Map<String, dynamic>> existing = await db.query(
      'doctors',
      where: 'LOWER(email) = ? OR LOWER(username) = ?',
      whereArgs: [cleanEmail, cleanUsername],
    );

    if (existing.isNotEmpty) {
      return false; // Already registered
    }

    await db.insert(
      'doctors',
      {
        'fullName': fullName.trim(),
        'email': cleanEmail,
        'username': cleanUsername,
        'password': password,
        'licenseNumber': licenseNumber.trim(),
        'clinicLocation': clinicLocation.trim(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }

  /// Validate doctor credentials
  Future<Map<String, dynamic>?> loginDoctor({
    required String emailOrUsername,
    required String password,
  }) async {
    final db = await database;
    await ensureDoctorTable();

    final cleanInput = emailOrUsername.trim().toLowerCase();
    final List<Map<String, dynamic>> results = await db.query(
      'doctors',
      where: '(LOWER(email) = ? OR LOWER(username) = ?) AND password = ?',
      whereArgs: [cleanInput, cleanInput, password],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// Check if any doctor account exists
  Future<bool> hasAnyDoctor() async {
    final db = await database;
    await ensureDoctorTable();
    final List<Map<String, dynamic>> results = await db.query('doctors', limit: 1);
    return results.isNotEmpty;
  }
}
