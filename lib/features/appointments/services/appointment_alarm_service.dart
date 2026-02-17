import 'dart:developer';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import '../models/appointment_entity.dart';

// Re-notify offsets in minutes after each tier fires
const List<int> kRenotifyOffsetMinutes = [5, 10, 20];

/// Background alarm callback — MUST be top-level or static.
@pragma('vm:entry-point')
void appointmentAlarmCallback(int alarmId, Map<String, dynamic> params) async {
  final title = params['title'] as String? ?? 'Appointment';
  final description = params['description'] as String? ?? '';
  final timeLabel = params['timeLabel'] as String? ?? '';
  final appointmentId = params['appointmentId'] as int? ?? 0;

  log('AppointmentAlarmService: Alarm $alarmId fired for "$title" ($timeLabel)');

  if (await Vibration.hasVibrator()) {
    Vibration.vibrate(pattern: [0, 300, 100, 300]);
  }

  final plugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await plugin.initialize(initSettings);

  const androidDetails = AndroidNotificationDetails(
    'synapse_runner_appointments',
    'Appointment Reminders',
    channelDescription: 'Reminders for upcoming appointments',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    playSound: false,
    enableVibration: false,
  );

  final body = description.isNotEmpty ? '$description — $timeLabel' : timeLabel;

  await plugin.show(
    alarmId,
    title,
    body,
    const NotificationDetails(android: androidDetails),
    payload: '/appointments/$appointmentId',
  );
}

class AppointmentAlarmService {
  static const int _kBase = 5000;
  static const int _kApptSlots = 100; // slots per appointment
  // Layout per appointment:
  //   Tier 0 (24h):   offsets 0–3  (0=main, 1–3=re-notifies)
  //   Tier 1 (1h):    offsets 10–13
  //   Tier 2 (15min): offsets 20–23

  static int _alarmId(int apptId, int tierIndex, int offset) =>
      _kBase + (apptId * _kApptSlots) + (tierIndex * 10) + offset;

  static String _tierLabel(int minutes) {
    if (minutes >= 1440) return '24 hours before';
    if (minutes >= 60) return '1 hour before';
    return '15 minutes before';
  }

  /// Schedule all tier alarms and their re-notifies for an appointment.
  static Future<void> scheduleAlarmsForAppointment(
      AppointmentEntity appt) async {
    final now = DateTime.now();

    for (int t = 0; t < kAppointmentTierMinutes.length; t++) {
      final tierMinutes = kAppointmentTierMinutes[t];
      final tierTime = appt.dateTime.subtract(Duration(minutes: tierMinutes));

      if (tierTime.isBefore(now)) {
        log('AppointmentAlarmService: Skipping tier $t (past) for appt ${appt.id}');
        continue;
      }

      final label = _tierLabel(tierMinutes);
      final mainId = _alarmId(appt.id, t, 0);

      log('AppointmentAlarmService: Scheduling "$label" alarm (ID $mainId) for "${appt.title}" at $tierTime');

      final params = {
        'title': appt.title,
        'description': appt.description ?? '',
        'timeLabel': label,
        'appointmentId': appt.id,
        'tierMinutes': tierMinutes,
      };

      await AndroidAlarmManager.oneShotAt(
        tierTime,
        mainId,
        appointmentAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: params,
      );

      // Schedule re-notifies at +5, +10, +20 min after the tier fires
      for (int r = 0; r < kRenotifyOffsetMinutes.length; r++) {
        final renotifyTime =
            tierTime.add(Duration(minutes: kRenotifyOffsetMinutes[r]));

        // Don't schedule re-notifies that would fire at/after the appointment
        if (!renotifyTime.isBefore(appt.dateTime)) continue;

        final reId = _alarmId(appt.id, t, r + 1);
        log('AppointmentAlarmService: Scheduling re-notify (ID $reId) at $renotifyTime');

        await AndroidAlarmManager.oneShotAt(
          renotifyTime,
          reId,
          appointmentAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {...params, 'timeLabel': '$label (reminder)'},
        );
      }
    }
  }

  /// Cancel re-notify alarms for a specific tier (called when user confirms).
  static Future<void> cancelTierRenotifies(
      int apptId, int tierMinutes) async {
    final tierIndex = kAppointmentTierMinutes.indexOf(tierMinutes);
    if (tierIndex < 0) return;

    for (int r = 1; r <= kRenotifyOffsetMinutes.length; r++) {
      final id = _alarmId(apptId, tierIndex, r);
      await AndroidAlarmManager.cancel(id);
    }
    log('AppointmentAlarmService: Cancelled re-notifies for appt $apptId tier ${_tierLabel(tierMinutes)}');
  }

  /// Cancel all alarms for an appointment (called on delete or complete).
  static Future<void> cancelAllAlarmsForAppointment(int apptId) async {
    for (int t = 0; t < kAppointmentTierMinutes.length; t++) {
      for (int offset = 0; offset <= kRenotifyOffsetMinutes.length; offset++) {
        await AndroidAlarmManager.cancel(_alarmId(apptId, t, offset));
      }
    }
    log('AppointmentAlarmService: Cancelled all alarms for appt $apptId');
  }

  /// Reschedule alarms for all future, incomplete appointments (app startup).
  static Future<void> rescheduleAllAppointments(
      List<AppointmentEntity> appointments) async {
    final now = DateTime.now();
    int scheduled = 0;
    for (final appt in appointments) {
      if (!appt.isCompleted && appt.dateTime.isAfter(now)) {
        await scheduleAlarmsForAppointment(appt);
        scheduled++;
      }
    }
    log('AppointmentAlarmService: Rescheduled alarms for $scheduled appointments');
  }
}
