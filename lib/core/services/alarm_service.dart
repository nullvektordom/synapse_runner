import 'dart:developer';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import '../../features/meds/models/medication_entity.dart';

// Background callback — receives alarm ID and params map.
// MUST be top-level or static.
@pragma('vm:entry-point')
void medAlarmCallback(int alarmId, Map<String, dynamic> params) async {
  final medName = params['medName'] as String? ?? 'Medication';
  final dosage = params['dosage'] as String? ?? '';
  final scheduledTime = params['scheduledTime'] as String? ?? '';

  log('AlarmService: Alarm $alarmId triggered for $medName at $scheduledTime');

  // Gentle vibration pattern: pulse-pause-pulse-pause-pulse
  if (await Vibration.hasVibrator()) {
    Vibration.vibrate(pattern: [0, 200, 150, 200, 150, 200]);
  }

  // Initialize notifications for this isolate
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  const androidDetails = AndroidNotificationDetails(
    'synapse_runner_meds',
    'Medication Reminders',
    channelDescription: 'Reminders to take your medication',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    playSound: false,
    enableVibration: false,
  );

  await flutterLocalNotificationsPlugin.show(
    alarmId,
    'Medication Reminder',
    '$medName $dosage — $scheduledTime',
    const NotificationDetails(android: androidDetails),
    payload: '/take-meds',
  );
}

class AlarmService {
  static const int kAlarmIdBase = 1000;
  static const int kMaxTimesPerMed = 20;
  static const int kTestAlarmId = 888;

  static int _alarmId(int medId, int timeIndex) =>
      kAlarmIdBase + (medId * kMaxTimesPerMed) + timeIndex;

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    log('AlarmService: Initialized AndroidAlarmManager');
  }

  /// Schedule all alarms for a single medication.
  static Future<void> scheduleAlarmsForMedication(
      MedicationEntity med) async {
    final now = DateTime.now();

    for (int i = 0; i < med.scheduledTimesMinutes.length; i++) {
      final minutes = med.scheduledTimesMinutes[i];
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      var nextAlarm = DateTime(now.year, now.month, now.day, hour, minute);
      if (now.isAfter(nextAlarm)) {
        nextAlarm = nextAlarm.add(const Duration(days: 1));
      }

      final id = _alarmId(med.id, i);
      final timeStr = minutes.toTimeString();

      log('AlarmService: Scheduling alarm $id for ${med.medName} at $timeStr');

      await AndroidAlarmManager.periodic(
        const Duration(hours: 24),
        id,
        medAlarmCallback,
        startAt: nextAlarm,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {
          'medName': med.medName,
          'dosage': med.dosage,
          'scheduledTime': timeStr,
          'medId': med.id,
        },
      );
    }
  }

  /// Cancel all alarms for a medication.
  static Future<void> cancelAlarmsForMedication(int medId) async {
    for (int i = 0; i < kMaxTimesPerMed; i++) {
      await AndroidAlarmManager.cancel(_alarmId(medId, i));
    }
    log('AlarmService: Cancelled all alarms for med $medId');
  }

  /// Reschedule alarms for all medications (called on app startup).
  static Future<void> rescheduleAllAlarms(
      List<MedicationEntity> meds) async {
    for (final med in meds) {
      await scheduleAlarmsForMedication(med);
    }
    log('AlarmService: Rescheduled alarms for ${meds.length} medications');
  }

  /// Test alarm for debugging — fires in 1 minute.
  static Future<void> scheduleTestAlarm() async {
    log('AlarmService: Scheduling test alarm for 1 minute from now');

    await AndroidAlarmManager.oneShot(
      const Duration(minutes: 1),
      kTestAlarmId,
      medAlarmCallback,
      exact: true,
      wakeup: true,
      params: {
        'medName': 'Test Med',
        'dosage': 'Test Dose',
        'scheduledTime': 'NOW',
        'medId': 0,
      },
    );
  }
}
