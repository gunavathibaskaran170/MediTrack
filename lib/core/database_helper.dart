import 'dart:convert';
import 'dart:io';
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
    if (kIsWeb) throw UnsupportedError("SQLite not supported on Web");
    if (_database != null) return _database!;
    _database = await _initDB('meditrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint("SQLITE DATABASE PATH: $path");

    if (!kIsWeb) {
      try {
        final dir = Directory('c:/Users/AMRUDAVARSHINI/Downloads/Hardware');
        if (await dir.exists()) {
          final file = File('${dir.path}/db_path.txt');
          await file.writeAsString(path);
          debugPrint("Successfully wrote database path to db_path.txt");
        }
      } catch (e) {
        debugPrint("Error writing database path to db_path.txt: $e");
      }
    }

    return await openDatabase(
      path,
      version: 3,
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
        created_at TEXT,
        profession TEXT,
        organization TEXT,
        work_email TEXT,
        work_phone TEXT,
        bio TEXT
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
        created_at TEXT,
        instructions TEXT,
        precautions TEXT,
        side_effects TEXT
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
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profession TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN organization TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN work_email TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN work_phone TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN bio TEXT');
      } catch (e) {
        debugPrint("Error migrating users professional fields: $e");
      }
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN instructions TEXT');
        await db.execute('ALTER TABLE medicines ADD COLUMN precautions TEXT');
        await db.execute('ALTER TABLE medicines ADD COLUMN side_effects TEXT');
      } catch (e) {
        debugPrint("Error migrating medicines care instructions: $e");
      }
    }
  }

  // --- WEB FALLBACK HELPERS ---
  Future<User?> _getWebUser(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('web_user_$id');
    if (userJson != null) {
      return User.fromMap(jsonDecode(userJson));
    }
    if (id == 1) {
      return User(
        id: 1,
        name: 'Rajan Kumar',
        age: 58,
        gender: 'Male',
        bloodGroup: 'O+',
        conditions: 'Diabetes,Hypertension',
        allergies: 'Penicillin',
        ecName: 'Priya Kumar',
        ecPhone: '+91-98765-43210',
        hospitalPhone: '+91-11-2345-6789',
        profession: 'Senior Software Engineer',
        organization: 'Apollo Hospitals Group',
        workEmail: 'rajan.kumar@apollo.com',
        workPhone: '+91-98765-99999',
        bio: 'Passionate about healthcare tech and patient monitoring systems. Managing medications diligently.',
      );
    }
    return null;
  }

  Future<int> _saveWebUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('web_user_${user.id ?? 1}', jsonEncode(user.toMap()));
    return user.id ?? 1;
  }

  // --- USER OPERATIONS ---
  Future<User?> getUser(int id) async {
    if (kIsWeb) return await _getWebUser(id);
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertUser(User user) async {
    if (kIsWeb) return await _saveWebUser(user);
    final db = await database;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUser(User user) async {
    if (kIsWeb) return await _saveWebUser(user);
    final db = await database;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // --- VITALS OPERATIONS ---
  Future<List<Vital>> getVitals({int? limitDays}) async {
    if (kIsWeb) return [];
    final db = await database;
    if (limitDays != null) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
      final cutoffStr = dateFormat.format(cutoffDate);
      final maps = await db.query(
        'vitals',
        where: 'date >= ?',
        whereArgs: [cutoffStr],
        orderBy: 'date DESC, created_at DESC',
      );
      return maps.map((m) => Vital.fromMap(m)).toList();
    } else {
      final maps = await db.query('vitals', orderBy: 'date DESC, created_at DESC');
      return maps.map((m) => Vital.fromMap(m)).toList();
    }
  }

  Future<Vital?> getTodayVitals() async {
    if (kIsWeb) return null;
    final db = await database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final maps = await db.query(
      'vitals',
      where: 'date = ?',
      whereArgs: [todayStr],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Vital.fromMap(maps.first);
    }
    return null;
  }

  Future<Vital?> getLatestVital() async {
    if (kIsWeb) return null;
    final db = await database;
    final maps = await db.query(
      'vitals',
      orderBy: 'created_at DESC',
      limit: 1,
    );
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

  // --- WEB MEDICINES HELPERS ---
  Future<List<Medicine>> _getWebMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final medicinesJson = prefs.getString('web_medicines');
    if (medicinesJson != null) {
      final List<dynamic> list = jsonDecode(medicinesJson);
      return list.map((e) => Medicine.fromMap(e)).toList();
    }
    final defaultList = [
      Medicine(
        id: 1,
        name: 'Metformin Hydrochloride 500mg',
        dosage: 1,
        unit: 'tablet(s)',
        frequency: 'Twice daily',
        reminderTimes: ['08:00', '20:30'],
        startDate: '2026-06-01',
        isActive: true,
        instructions: 'Take with or immediately after food to reduce stomach upset.',
        precautions: 'Do not take with excessive alcohol. Monitor blood sugar levels regularly.',
        sideEffects: 'May cause mild nausea, diarrhea, or metallic taste initially.',
      ),
      Medicine(
        id: 2,
        name: 'Atorvastatin 10mg',
        dosage: 1,
        unit: 'tablet(s)',
        frequency: 'Once daily (Night)',
        reminderTimes: ['21:30'],
        startDate: '2026-06-01',
        isActive: true,
        instructions: 'Take at night. Can be taken with or without food.',
        precautions: 'Avoid drinking grapefruit juice. Inform doctor if muscle pain occurs.',
        sideEffects: 'Mild headache, muscle aches, or nasal congestion.',
      ),
      Medicine(
        id: 3,
        name: 'Amlodipine 5mg',
        dosage: 1,
        unit: 'tablet(s)',
        frequency: 'Once daily (Morning)',
        reminderTimes: ['09:00'],
        startDate: '2026-06-01',
        isActive: true,
        instructions: 'Take in the morning. Swallow whole with a glass of water.',
        precautions: 'Avoid sudden posture changes to prevent dizziness. Do not skip doses.',
        sideEffects: 'Ankle swelling, dizziness, flushing, or fatigue.',
      ),
      Medicine(
        id: 4,
        name: 'Paracetamol 650mg',
        dosage: 1,
        unit: 'tablet(s)',
        frequency: 'As needed (SOS)',
        reminderTimes: ['14:00'],
        startDate: '2026-06-01',
        isActive: false,
        instructions: 'Take after food for mild pain or fever. Maintain 4-6 hours gap.',
        precautions: 'Do not exceed 4 tablets in 24 hours. Avoid if taking other paracetamol products.',
        sideEffects: 'Rare, but skin rash or liver damage on high overdose.',
      ),
    ];
    await prefs.setString('web_medicines', jsonEncode(defaultList.map((e) => e.toMap()).toList()));
    return defaultList;
  }

  Future<int> _saveWebMedicine(Medicine med) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _getWebMedicines();
    int newId = med.id ?? DateTime.now().millisecondsSinceEpoch;
    final newMed = Medicine(
      id: newId,
      userId: med.userId,
      name: med.name,
      dosage: med.dosage,
      unit: med.unit,
      frequency: med.frequency,
      reminderTimes: med.reminderTimes,
      startDate: med.startDate,
      endDate: med.endDate,
      isActive: med.isActive,
      createdAt: med.createdAt,
      instructions: med.instructions,
      precautions: med.precautions,
      sideEffects: med.sideEffects,
    );
    list.removeWhere((e) => e.id == newId);
    list.add(newMed);
    await prefs.setString('web_medicines', jsonEncode(list.map((e) => e.toMap()).toList()));
    return newId;
  }

  Future<int> _deleteWebMedicine(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _getWebMedicines();
    list.removeWhere((e) => e.id == id);
    await prefs.setString('web_medicines', jsonEncode(list.map((e) => e.toMap()).toList()));
    return 1;
  }

  Future<int> _toggleWebMedicineActive(int id, int active) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _getWebMedicines();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      final med = list[index];
      list[index] = Medicine(
        id: med.id,
        userId: med.userId,
        name: med.name,
        dosage: med.dosage,
        unit: med.unit,
        frequency: med.frequency,
        reminderTimes: med.reminderTimes,
        startDate: med.startDate,
        endDate: med.endDate,
        isActive: active == 1,
        createdAt: med.createdAt,
        instructions: med.instructions,
        precautions: med.precautions,
        sideEffects: med.sideEffects,
      );
      await prefs.setString('web_medicines', jsonEncode(list.map((e) => e.toMap()).toList()));
    }
    return 1;
  }

  // --- MEDICINE OPERATIONS ---
  Future<List<Medicine>> getMedicines() async {
    if (kIsWeb) return await _getWebMedicines();
    final db = await database;
    final maps = await db.query('medicines', orderBy: 'id DESC');
    return maps.map((m) => Medicine.fromMap(m)).toList();
  }

  Future<int> insertMedicine(Medicine medicine) async {
    if (kIsWeb) return await _saveWebMedicine(medicine);
    final db = await database;
    return await db.insert('medicines', medicine.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMedicine(Medicine medicine) async {
    if (kIsWeb) return await _saveWebMedicine(medicine);
    final db = await database;
    return await db.update('medicines', medicine.toMap(), where: 'id = ?', whereArgs: [medicine.id]);
  }

  Future<int> deleteMedicine(int id) async {
    if (kIsWeb) return await _deleteWebMedicine(id);
    final db = await database;
    return await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleMedicineActive(int id, int active) async {
    if (kIsWeb) return await _toggleWebMedicineActive(id, active);
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
    if (kIsWeb) return;
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
      'hospital_phone': '+91-11-2345-6789',
      'created_at': nowString,
      'profession': 'Senior Software Engineer',
      'organization': 'Apollo Hospitals Group',
      'work_email': 'rajan.kumar@apollo.com',
      'work_phone': '+91-98765-99999',
      'bio': 'Passionate about healthcare tech and patient monitoring systems. Managing medications diligently.',
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
        'name': 'Metformin Hydrochloride 500mg',
        'dosage': 1.0,
        'unit': 'tablet(s)',
        'frequency': 'Twice daily',
        'reminder_times': jsonEncode(['08:00', '20:30']),
        'start_date': dateFormat.format(today.subtract(const Duration(days: 35))),
        'end_date': '',
        'is_active': 1,
        'created_at': nowString,
        'instructions': 'Take with or immediately after food to reduce stomach upset.',
        'precautions': 'Do not take with excessive alcohol. Monitor blood sugar levels regularly.',
        'side_effects': 'May cause mild nausea, diarrhea, or metallic taste initially.'
      },
      {
        'id': 2,
        'name': 'Atorvastatin 10mg',
        'dosage': 1.0,
        'unit': 'tablet(s)',
        'frequency': 'Once daily (Night)',
        'reminder_times': jsonEncode(['21:30']),
        'start_date': dateFormat.format(today.subtract(const Duration(days: 35))),
        'end_date': '',
        'is_active': 1,
        'created_at': nowString,
        'instructions': 'Take at night. Can be taken with or without food.',
        'precautions': 'Avoid drinking grapefruit juice. Inform doctor if muscle pain occurs.',
        'side_effects': 'Mild headache, muscle aches, or nasal congestion.'
      },
      {
        'id': 3,
        'name': 'Amlodipine 5mg',
        'dosage': 1.0,
        'unit': 'tablet(s)',
        'frequency': 'Once daily (Morning)',
        'reminder_times': jsonEncode(['09:00']),
        'start_date': dateFormat.format(today.subtract(const Duration(days: 35))),
        'end_date': '',
        'is_active': 1,
        'created_at': nowString,
        'instructions': 'Take in the morning. Swallow whole with a glass of water.',
        'precautions': 'Avoid sudden posture changes to prevent dizziness. Do not skip doses.',
        'side_effects': 'Ankle swelling, dizziness, flushing, or fatigue.'
      },
      {
        'id': 4,
        'name': 'Paracetamol 650mg',
        'dosage': 1.0,
        'unit': 'tablet(s)',
        'frequency': 'As needed (SOS)',
        'reminder_times': jsonEncode(['14:00']),
        'start_date': dateFormat.format(today.subtract(const Duration(days: 35))),
        'end_date': '',
        'is_active': 0,
        'created_at': nowString,
        'instructions': 'Take after food for mild pain or fever. Maintain 4-6 hours gap.',
        'precautions': 'Do not exceed 4 tablets in 24 hours. Avoid if taking other paracetamol products.',
        'side_effects': 'Rare, but skin rash or liver damage on high overdose.'
      }
    ];

    for (var med in medicinesList) {
      batch.insert('medicines', med);
    }

    for (int i = 30; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = dateFormat.format(date);

      _addLog(batch, random, 1, dateStr, '08:00');
      _addLog(batch, random, 1, dateStr, '20:30');
      _addLog(batch, random, 2, dateStr, '21:30');
      _addLog(batch, random, 3, dateStr, '09:00');
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
