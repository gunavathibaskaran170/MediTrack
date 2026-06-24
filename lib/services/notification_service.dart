import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    // 1. Initialize time zones
    tz.initializeTimeZones();

    // 2. Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS / Darwin settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 4. Initialize plugin
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // 5. Create Android Channel
    const androidChannel = AndroidNotificationChannel(
      'meditrack_reminders',
      'Medicine Reminders',
      description: 'Daily alerts for taking scheduled medication',
      importance: Importance.high,
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Request permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    // Request Android 13+ permission
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await androidImplementation?.requestNotificationsPermission() ?? false;

    // Request iOS permission
    final iosImplementation =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;

    return androidGranted || iosGranted;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint("Notification tapped: ${response.payload}");
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    debugPrint("Background Notification Action tapped: ${response.actionId} - ${response.payload}");
  }

  /// 1. Schedule Daily Medicine Reminder
  Future<void> scheduleMedicineReminder({
    required int medicineId,
    required String medicineName,
    required double dosage,
    required String unit,
    required String timeStr, // Format "HH:mm"
  }) async {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Unique notification ID per medicine + hour combination
    final id = medicineId * 100 + hour;

    const androidDetails = AndroidNotificationDetails(
      'meditrack_reminders',
      'Medicine Reminders',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('taken', '✓ Taken', showsUserInterface: true),
        AndroidNotificationAction('snooze', '⏰ Snooze 15 min', showsUserInterface: true),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'medicine_actions',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule everyday at specific HH:mm
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      id,
      '💊 Time for $medicineName',
      'Take $dosage $unit now',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'medicine', 'id': medicineId, 'time': timeStr}),
    );

    // 2. Schedule Missed Dose Alert (30 mins after scheduled time)
    await scheduleMissedDoseAlert(
      medicineId: medicineId,
      medicineName: medicineName,
      scheduledTimeStr: timeStr,
      hour: hour,
      minute: minute,
    );
  }

  /// Schedules missed dose warning 30 minutes after scheduled time
  Future<void> scheduleMissedDoseAlert({
    required int medicineId,
    required String medicineName,
    required String scheduledTimeStr,
    required int hour,
    required int minute,
  }) async {
    // Unique ID for missed dose alert
    final id = medicineId * 1000 + hour;

    final targetTime = _nextInstanceOfTime(hour, minute).add(const Duration(minutes: 30));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'meditrack_reminders',
        'Medicine Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      '⚠️ Missed Dose',
      'You missed $medicineName. Log it now.',
      targetTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'missed', 'id': medicineId, 'time': scheduledTimeStr}),
    );
  }

  /// Schedules a one-time snooze reminder 15 minutes from now
  Future<void> scheduleSnoozeReminder({
    required int medicineId,
    required String medicineName,
    required double dosage,
    required String unit,
  }) async {
    final id = medicineId * 10000 + DateTime.now().minute;
    final targetTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 15));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'meditrack_reminders',
        'Medicine Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      '💊 Time for $medicineName (Snoozed)',
      'Take $dosage $unit now',
      targetTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'medicine', 'id': medicineId}),
    );
  }

  /// 3. Schedule Appointment Alert (1 day before follow-up date at 09:00)
  Future<void> scheduleAppointmentReminder({
    required int visitId,
    required String doctorName,
    required String hospital,
    required String followUpDateStr, // Format "yyyy-MM-dd"
  }) async {
    final format = DateFormat('yyyy-MM-dd');
    final parsedDate = format.parse(followUpDateStr);

    // 1 day before at 09:00 AM
    final alertTime = parsedDate.subtract(const Duration(days: 1)).add(const Duration(hours: 9));
    if (alertTime.isBefore(DateTime.now())) return;

    final id = visitId * 10;

    final scheduledDate = tz.TZDateTime.from(alertTime, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'meditrack_reminders',
        'Medicine Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      '🏥 Doctor Follow-up Tomorrow',
      'Follow-up with $doctorName at $hospital',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'followup', 'id': visitId}),
    );
  }

  /// 4. Schedule Daily Vitals Reminder (every day at 08:00 AM)
  Future<void> scheduleDailyVitalsReminder() async {
    const id = 9999;
    final scheduledDate = _nextInstanceOfTime(8, 0);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'meditrack_reminders',
        'Medicine Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      '📊 Log Your Vitals',
      "Take a moment to record today's health readings",
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'vitals'}),
    );
  }

  /// Cancels all notifications for a specific medicine
  Future<void> cancelMedicineReminders(int medicineId) async {
    // Cancel dose reminders and missed alerts
    // Since notifications are scheduled with unique IDs based on medicine ID,
    // we can retrieve active notifications and filter by ID prefix or cancel them.
    // For simplicity, we cancel the potential IDs we scheduled.
    // ID formats: medicineId * 100 + hour, medicineId * 1000 + hour
    for (int hour = 0; hour < 24; hour++) {
      await _plugin.cancel(medicineId * 100 + hour);
      await _plugin.cancel(medicineId * 1000 + hour);
    }
  }

  /// Cancels all scheduled local notifications
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Helper to get next instance of a specific daily time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
