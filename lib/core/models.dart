import 'dart:convert';

class User {
  final int? id;
  final String name;
  final int? age;
  final String? gender;
  final String? bloodGroup;
  final String? conditions; // comma-separated
  final String? allergies;
  final String? ecName;
  final String? ecPhone;
  final String? createdAt;

  User({
    this.id,
    required this.name,
    this.age,
    this.gender,
    this.bloodGroup,
    this.conditions,
    this.allergies,
    this.ecName,
    this.ecPhone,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'blood_group': bloodGroup,
      'conditions': conditions,
      'allergies': allergies,
      'ec_name': ecName,
      'ec_phone': ecPhone,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      bloodGroup: map['blood_group'] as String?,
      conditions: map['conditions'] as String?,
      allergies: map['allergies'] as String?,
      ecName: map['ec_name'] as String?,
      ecPhone: map['ec_phone'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}

class Vital {
  final int? id;
  final int? userId;
  final String date; // yyyy-MM-dd
  final double? bpSystolic;
  final double? bpDiastolic;
  final double? bloodSugar;
  final String? sugarType; // fasting / post_meal
  final double? temperature;
  final double? weight;
  final double? spo2;
  final double? heartRate;
  final String? notes;
  final String? createdAt;

  Vital({
    this.id,
    this.userId,
    required this.date,
    this.bpSystolic,
    this.bpDiastolic,
    this.bloodSugar,
    this.sugarType,
    this.temperature,
    this.weight,
    this.spo2,
    this.heartRate,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId ?? 1,
      'date': date,
      'bp_systolic': bpSystolic,
      'bp_diastolic': bpDiastolic,
      'blood_sugar': bloodSugar,
      'sugar_type': sugarType,
      'temperature': temperature,
      'weight': weight,
      'spo2': spo2,
      'heart_rate': heartRate,
      'notes': notes,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Vital.fromMap(Map<String, dynamic> map) {
    return Vital(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      date: map['date'] as String,
      bpSystolic: map['bp_systolic'] != null ? (map['bp_systolic'] as num).toDouble() : null,
      bpDiastolic: map['bp_diastolic'] != null ? (map['bp_diastolic'] as num).toDouble() : null,
      bloodSugar: map['blood_sugar'] != null ? (map['blood_sugar'] as num).toDouble() : null,
      sugarType: map['sugar_type'] as String?,
      temperature: map['temperature'] != null ? (map['temperature'] as num).toDouble() : null,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      spo2: map['spo2'] != null ? (map['spo2'] as num).toDouble() : null,
      heartRate: map['heart_rate'] != null ? (map['heart_rate'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}

class Medicine {
  final int? id;
  final int? userId;
  final String name;
  final double? dosage;
  final String? unit;
  final String? frequency;
  final List<String> reminderTimes; // JSON array of HH:mm
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final String? createdAt;

  Medicine({
    this.id,
    this.userId,
    required this.name,
    this.dosage,
    this.unit,
    this.frequency,
    required this.reminderTimes,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId ?? 1,
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'frequency': frequency,
      'reminder_times': jsonEncode(reminderTimes),
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    List<dynamic> parsedTimes = [];
    if (map['reminder_times'] != null) {
      try {
        parsedTimes = jsonDecode(map['reminder_times'] as String) as List<dynamic>;
      } catch (_) {
        parsedTimes = [];
      }
    }
    return Medicine(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      name: map['name'] as String,
      dosage: map['dosage'] != null ? (map['dosage'] as num).toDouble() : null,
      unit: map['unit'] as String?,
      frequency: map['frequency'] as String?,
      reminderTimes: parsedTimes.map((e) => e.toString()).toList(),
      startDate: map['start_date'] as String?,
      endDate: map['end_date'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String?,
    );
  }
}

class MedicationLog {
  final int? id;
  final int? medicineId;
  final int? userId;
  final String date; // yyyy-MM-dd
  final String scheduledTime; // HH:mm
  final String? actualTime; // HH:mm or DateTime string
  final String status; // taken / missed / snoozed / skipped

  MedicationLog({
    this.id,
    this.medicineId,
    this.userId,
    required this.date,
    required this.scheduledTime,
    this.actualTime,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicine_id': medicineId,
      'user_id': userId ?? 1,
      'date': date,
      'scheduled_time': scheduledTime,
      'actual_time': actualTime,
      'status': status,
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] as int?,
      medicineId: map['medicine_id'] as int?,
      userId: map['user_id'] as int?,
      date: map['date'] as String,
      scheduledTime: map['scheduled_time'] as String,
      actualTime: map['actual_time'] as String?,
      status: map['status'] as String,
    );
  }
}

class Symptom {
  final int? id;
  final int? userId;
  final String? date;
  final String? time;
  final String? symptomName;
  final int? severity; // 1=Mild, 2=Moderate, 3=Severe
  final String? notes;
  final String? createdAt;

  Symptom({
    this.id,
    this.userId,
    this.date,
    this.time,
    this.symptomName,
    this.severity,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId ?? 1,
      'date': date,
      'time': time,
      'symptom_name': symptomName,
      'severity': severity,
      'notes': notes,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Symptom.fromMap(Map<String, dynamic> map) {
    return Symptom(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      date: map['date'] as String?,
      time: map['time'] as String?,
      symptomName: map['symptom_name'] as String?,
      severity: map['severity'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}

class DoctorVisit {
  final int? id;
  final int? userId;
  final String doctorName;
  final String hospital;
  final String visitDate;
  final String? diagnosis;
  final String? notes;
  final String? followUpDate;
  final int? prescriptionId;

  DoctorVisit({
    this.id,
    this.userId,
    required this.doctorName,
    required this.hospital,
    required this.visitDate,
    this.diagnosis,
    this.notes,
    this.followUpDate,
    this.prescriptionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId ?? 1,
      'doctor_name': doctorName,
      'hospital': hospital,
      'visit_date': visitDate,
      'diagnosis': diagnosis,
      'notes': notes,
      'follow_up_date': followUpDate,
      'prescription_id': prescriptionId,
    };
  }

  factory DoctorVisit.fromMap(Map<String, dynamic> map) {
    return DoctorVisit(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      doctorName: map['doctor_name'] as String,
      hospital: map['hospital'] as String,
      visitDate: map['visit_date'] as String,
      diagnosis: map['diagnosis'] as String?,
      notes: map['notes'] as String?,
      followUpDate: map['follow_up_date'] as String?,
      prescriptionId: map['prescription_id'] as int?,
    );
  }
}

class Prescription {
  final int? id;
  final int? userId;
  final String imagePath;
  final String? doctorName;
  final String? visitDate;
  final String? notes;
  final String? createdAt;

  Prescription({
    this.id,
    this.userId,
    required this.imagePath,
    this.doctorName,
    this.visitDate,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId ?? 1,
      'image_path': imagePath,
      'doctor_name': doctorName,
      'visit_date': visitDate,
      'notes': notes,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      imagePath: map['image_path'] as String,
      doctorName: map['doctor_name'] as String?,
      visitDate: map['visit_date'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}
