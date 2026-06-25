import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('meditrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER,
        gender TEXT,
        blood_group TEXT,
        conditions TEXT,
        allergies TEXT,
        ec_name TEXT,
        ec_phone TEXT,
        hospital_phone TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE vitals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        date TEXT NOT NULL,
        bp_systolic REAL,
        bp_diastolic REAL,
        blood_sugar REAL,
        sugar_type TEXT,
        temperature REAL,
        weight REAL,
        spo2 REAL,
        heart_rate REAL,
        notes TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        dosage REAL,
        unit TEXT,
        frequency TEXT,
        reminder_times TEXT,
        start_date TEXT,
        end_date TEXT,
        is_active INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE medication_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER,
        user_id INTEGER,
        date TEXT NOT NULL,
        scheduled_time TEXT,
        actual_time TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE symptoms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        date TEXT,
        time TEXT,
        symptom_name TEXT,
        severity INTEGER,
        notes TEXT,
        body_region TEXT,
        duration TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE doctor_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        doctor_name TEXT,
        hospital TEXT,
        visit_date TEXT,
        diagnosis TEXT,
        notes TEXT,
        follow_up_date TEXT,
        prescription_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE prescriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        image_path TEXT,
        doctor_name TEXT,
        visit_date TEXT,
        notes TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sos_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        timestamp TEXT,
        contact_notified TEXT,
        sms_sent INTEGER,
        call_initiated INTEGER,
        notes TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN hospital_phone TEXT');
      } catch (e) {
        debugPrint("Error migrating users hospital_phone: $e");
      }
      try {
        await db.execute('ALTER TABLE symptoms ADD COLUMN body_region TEXT');
        await db.execute('ALTER TABLE symptoms ADD COLUMN duration TEXT');
      } catch (e) {
        debugPrint("Error migrating symptoms body_region/duration: $e");
      }
      try {
        await db.execute('''
          CREATE TABLE sos_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            timestamp TEXT,
            contact_notified TEXT,
            sms_sent INTEGER,
            call_initiated INTEGER,
            notes TEXT
          )
        ''');
      } catch (e) {
        debugPrint("Error creating sos_logs table: $e");
      }
    }
  }

  // --- USER OPERATIONS ---
  Future<User?> getUser(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // --- VITALS OPERATIONS ---
  Future<List<Vital>> getVitals({int? limitDays}) async {
    final db = await database;
    if (limitDays != null) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
      final cutoffStr = dateFormat.format(cutoffDate);
      final maps = await db.query(
        'vitals',
        where: 'date >= ?',
        whereArgs: [cutoffStr],
        orderBy: 'date DESC',
      );
      return maps.map((m) => Vital.fromMap(m)).toList();
    } else {
      final maps = await db.query('vitals', orderBy: 'date DESC');
      return maps.map((m) => Vital.fromMap(m)).toList();
    }
  }

  Future<Vital?> getTodayVitals() async {
    final db = await database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final maps = await db.query('vitals', where: 'date = ?', whereArgs: [todayStr]);
    if (maps.isNotEmpty) {
      return Vital.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertVital(Vital vital) async {
    final db = await database;
    return await db.insert('vitals', vital.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateVital(Vital vital) async {
    final db = await database;
    return await db.update('vitals', vital.toMap(), where: 'id = ?', whereArgs: [vital.id]);
  }

  Future<int> deleteVital(int id) async {
    final db = await database;
    return await db.delete('vitals', where: 'id = ?', whereArgs: [id]);
  }

  // --- MEDICINE OPERATIONS ---
  Future<List<Medicine>> getMedicines() async {
    final db = await database;
    final maps = await db.query('medicines', orderBy: 'id DESC');
    return maps.map((m) => Medicine.fromMap(m)).toList();
  }

  Future<int> insertMedicine(Medicine medicine) async {
    final db = await database;
    return await db.insert('medicines', medicine.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMedicine(Medicine medicine) async {
    final db = await database;
    return await db.update('medicines', medicine.toMap(), where: 'id = ?', whereArgs: [medicine.id]);
  }

  Future<int> deleteMedicine(int id) async {
    final db = await database;
    return await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleMedicineActive(int id, int active) async {
    final db = await database;
    return await db.update('medicines', {'is_active': active}, where: 'id = ?', whereArgs: [id]);
  }

  // --- MEDICATION LOGS OPERATIONS ---
  Future<List<MedicationLog>> getMedicationLogs({int? limitDays}) async {
    final db = await database;
    if (limitDays != null) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
      final cutoffStr = dateFormat.format(cutoffDate);
      final maps = await db.query(
        'medication_logs',
        where: 'date >= ?',
        whereArgs: [cutoffStr],
        orderBy: 'date DESC',
      );
      return maps.map((m) => MedicationLog.fromMap(m)).toList();
    } else {
      final maps = await db.query('medication_logs', orderBy: 'date DESC');
      return maps.map((m) => MedicationLog.fromMap(m)).toList();
    }
  }

  Future<int> insertMedicationLog(MedicationLog log) async {
    final db = await database;
    return await db.insert('medication_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- SYMPTOMS OPERATIONS ---
  Future<List<Symptom>> getSymptoms() async {
    final db = await database;
    final maps = await db.query('symptoms', orderBy: 'date DESC, time DESC');
    return maps.map((m) => Symptom.fromMap(m)).toList();
  }

  Future<int> insertSymptom(Symptom symptom) async {
    final db = await database;
    return await db.insert('symptoms', symptom.toMap());
  }

  Future<int> deleteSymptom(int id) async {
    final db = await database;
    return await db.delete('symptoms', where: 'id = ?', whereArgs: [id]);
  }

  // --- DOCTOR VISITS OPERATIONS ---
  Future<List<DoctorVisit>> getDoctorVisits() async {
    final db = await database;
    final maps = await db.query('doctor_visits', orderBy: 'visit_date DESC');
    return maps.map((m) => DoctorVisit.fromMap(m)).toList();
  }

  Future<int> insertDoctorVisit(DoctorVisit visit) async {
    final db = await database;
    return await db.insert('doctor_visits', visit.toMap());
  }

  Future<int> updateDoctorVisit(DoctorVisit visit) async {
    final db = await database;
    return await db.update(
      'doctor_visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<int> deleteDoctorVisit(int id) async {
    final db = await database;
    return await db.delete('doctor_visits', where: 'id = ?', whereArgs: [id]);
  }

  // --- PRESCRIPTIONS OPERATIONS ---
  Future<List<Prescription>> getPrescriptions() async {
    final db = await database;
    final maps = await db.query('prescriptions', orderBy: 'created_at DESC');
    return maps.map((m) => Prescription.fromMap(m)).toList();
  }

  Future<int> insertPrescription(Prescription prescription) async {
    final db = await database;
    return await db.insert('prescriptions', prescription.toMap());
  }

  Future<int> deletePrescription(int id) async {
    final db = await database;
    return await db.delete('prescriptions', where: 'id = ?', whereArgs: [id]);
  }

  // --- PURGE ALL DATA ---
  Future<void> purgeAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('vitals');
    await db.delete('medicines');
    await db.delete('medication_logs');
    await db.delete('symptoms');
    await db.delete('doctor_visits');
    await db.delete('prescriptions');
  }

  // --- SEEDER LOGIC ---
  Future<void> seedDemoDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool('demo_seeded') ?? false;

    if (isSeeded) return;

    final db = await database;
    final batch = db.batch();

    final nowString = DateTime.now().toIso8601String();
    batch.insert('users', {
      'id': 1,
      'name': 'Rajan Kumar',
      'age': 58,
      'gender': 'Male',
      'blood_group': 'O+',
      'conditions': 'Diabetes,Hypertension',
      'allergies': 'Penicillin',
      'ec_name': 'Priya Kumar',
      'ec_phone': '+91-98765-43210',
      'created_at': nowString
    });

    final random = Random();
    final dateFormat = DateFormat('yyyy-MM-dd');

    final today = DateTime.now();
    for (int i = 30; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = dateFormat.format(date);
      batch.insert('vitals', {
        'user_id': 1,
        'date': dateStr,
        'bp_systolic': (118 + random.nextInt(21)).toDouble(),
        'bp_diastolic': (74 + random.nextInt(15)).toDouble(),
        'blood_sugar': (110 + random.nextInt(59)).toDouble(),
        'sugar_type': 'fasting',
        'temperature': double.parse((36.4 + random.nextDouble() * 0.7).toStringAsFixed(1)),
        'weight': double.parse((74.0 + random.nextDouble() * 1.2).toStringAsFixed(1)),
        'spo2': (95 + random.nextInt(4)).toDouble(),
        'heart_rate': (68 + random.nextInt(17)).toDouble(),
        'notes': 'Routine reading.',
        'created_at': date.toIso8601String()
      });
    }

    final medicinesList = [
      {
        'id': 1,
        'name': 'Metformin',
        'dosage': 500.0,
        'unit': 'mg',
        'frequency': 'Twice daily',
        'reminder_times': jsonEncode(['08:00', '20:00']),
        'start_date': dateFormat.format(today.subtract(const Duration(days: 35))),
        'end_date': '',
        'is_active': 1,
        'created_at': nowString
      },
      {
        'id': 2,
        'name': 'Amlodipine',
        'dosage': 5.0,
        'unit': 'mg',
        'frequency': 'Once daily',
        'reminder_times': jsonEncode(['08:00']),
        'start_date': dateFormat.format(today.subtract(const Duration(days: 35))),
        'end_date': '',
        'is_active': 1,
        'created_at': nowString
      },
      {
        'id': 3,
        'name': 'Losartan',
        'dosage': 50.0,
        'unit': 'mg',
        'frequency': 'Once daily',
        'reminder_times': jsonEncode(['20:00']),
        'start_date': dateFormat.format(today.subtract(const Duration(days: 35))),
        'end_date': '',
        'is_active': 1,
        'created_at': nowString
      },
      {
        'id': 4,
        'name': 'Aspirin',
        'dosage': 75.0,
        'unit': 'mg',
        'frequency': 'Once daily',
        'reminder_times': jsonEncode(['08:00']),
        'start_date': dateFormat.format(today.subtract(const Duration(days: 35))),
        'end_date': '',
        'is_active': 1,
        'created_at': nowString
      }
    ];

    for (var med in medicinesList) {
      batch.insert('medicines', med);
    }

    for (int i = 30; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = dateFormat.format(date);

      _addLog(batch, random, 1, dateStr, '08:00');
      _addLog(batch, random, 1, dateStr, '20:00');
      _addLog(batch, random, 2, dateStr, '08:00');
      _addLog(batch, random, 3, dateStr, '20:00');
      _addLog(batch, random, 4, dateStr, '08:00');
    }

    final symptomList = [
      {'name': 'Headache', 'severity': 2, 'daysAgo': 28},
      {'name': 'Dizziness', 'severity': 1, 'daysAgo': 24},
      {'name': 'Fatigue', 'severity': 2, 'daysAgo': 20},
      {'name': 'Headache', 'severity': 1, 'daysAgo': 17},
      {'name': 'Chest tightness', 'severity': 2, 'daysAgo': 12},
      {'name': 'Fatigue', 'severity': 3, 'daysAgo': 8},
      {'name': 'Dizziness', 'severity': 2, 'daysAgo': 4},
      {'name': 'Nausea', 'severity': 1, 'daysAgo': 1},
    ];

    for (var sym in symptomList) {
      final symDate = today.subtract(Duration(days: sym['daysAgo'] as int));
      batch.insert('symptoms', {
        'user_id': 1,
        'date': dateFormat.format(symDate),
        'time': '14:30',
        'symptom_name': sym['name'],
        'severity': sym['severity'],
        'notes': 'Recorded in history timeline.',
        'created_at': symDate.toIso8601String()
      });
    }

    final v1Date = today.subtract(const Duration(days: 45));
    batch.insert('doctor_visits', {
      'user_id': 1,
      'doctor_name': 'Dr. Sharma',
      'hospital': 'City Hospital',
      'visit_date': dateFormat.format(v1Date),
      'diagnosis': 'Type 2 Diabetes — controlled',
      'notes': 'Patient reports compliance with medication. HbA1c is stable at 6.8%. Continue Metformin twice daily.',
      'follow_up_date': null,
      'prescription_id': null
    });

    final v2Date = today.subtract(const Duration(days: 20));
    batch.insert('doctor_visits', {
      'user_id': 1,
      'doctor_name': 'Dr. Mehta',
      'hospital': 'Lifeline Clinic',
      'visit_date': dateFormat.format(v2Date),
      'diagnosis': 'Hypertension — medication adjusted',
      'notes': 'Checked BP in clinic: 142/90 mmHg. Added Amlodipine 5mg once daily in morning. Instructed low sodium diet.',
      'follow_up_date': null,
      'prescription_id': null
    });

    final v3Date = today.subtract(const Duration(days: 5));
    batch.insert('doctor_visits', {
      'user_id': 1,
      'doctor_name': 'Dr. Sharma',
      'hospital': 'City Hospital',
      'visit_date': dateFormat.format(v3Date),
      'diagnosis': 'Routine checkup — all stable',
      'notes': 'Metabolic panel looks good. Blood sugar stable. Keep monitoring at home.',
      'follow_up_date': dateFormat.format(today.add(const Duration(days: 30))),
      'prescription_id': null
    });

    await batch.commit(noResult: true);
    await prefs.setBool('demo_seeded', true);
    debugPrint("Demo data successfully seeded.");
  }

  void _addLog(Batch batch, Random rand, int medId, String dateStr, String timeStr) {
    final val = rand.nextInt(100);
    String status = 'taken';
    String? actual;
    if (val < 90) {
      status = 'taken';
      actual = timeStr;
    } else if (val < 97) {
      status = 'missed';
    } else {
      status = rand.nextBool() ? 'snoozed' : 'skipped';
    }
    batch.insert('medication_logs', {
      'medicine_id': medId,
      'user_id': 1,
      'date': dateStr,
      'scheduled_time': timeStr,
      'actual_time': actual,
      'status': status
    });
  }

  // --- SOS LOG OPERATIONS ---
  Future<List<SosLog>> getSosLogs() async {
    final db = await database;
    final maps = await db.query('sos_logs', orderBy: 'timestamp DESC');
    return maps.map((m) => SosLog.fromMap(m)).toList();
  }

  Future<int> insertSosLog(SosLog log) async {
    final db = await database;
    return await db.insert('sos_logs', log.toMap());
  }
}
