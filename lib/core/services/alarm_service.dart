import 'dart:developer';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// The background callback
// MUST be top-level or static.
@pragma('vm:entry-point')
void alarmCallback() async {
  final DateTime now = DateTime.now();
  log('AlarmService: Alarm triggered at $now');
  
  // Initialize notifications for this isolate
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
      
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Show notification
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'synapse_runner_meds',
    'Medication Reminders',
    channelDescription: 'Reminders to take your medication',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );
  
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      
  await flutterLocalNotificationsPlugin.show(
    0,
    'Medication Reminder',
    'Time to take your meds!',
    platformChannelSpecifics,
    payload: '/medications',
  );
}

class AlarmService {
  // Use a unique ID for the alarm
  static const int kTestAlarmId = 888;

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    log('AlarmService: Initialized AndroidAlarmManager');
  }

  static Future<void> scheduleTestAlarm() async {
    log('AlarmService: Scheduling test alarm for 1 minute from now');
    
    // Schedule a one-shot alarm
    await AndroidAlarmManager.oneShot(
      const Duration(minutes: 1),
      kTestAlarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
    );
  }
}
