import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task_entity.dart';

class TaskNotificationService {
  static const int _taskNotificationId = 1000;
  static const String _channelId = 'current_task_channel';
  static const String _channelName = 'Current Task';
  static const String _channelDescription = 'Shows your current active task';

  final FlutterLocalNotificationsPlugin _notifications;

  TaskNotificationService(this._notifications);

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    // Create notification channel for persistent task notifications
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> showTaskNotification(TaskEntity task) async {
    final duration = DateTime.now().difference(task.startTime);
    final minutes = duration.inMinutes;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Makes it persistent
      autoCancel: false, // Prevents dismissal by swipe
      playSound: false,
      enableVibration: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        task.description ?? '',
        contentTitle: 'Current Task: ${task.title}',
        summaryText: 'Running for $minutes min',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _taskNotificationId,
      'Current Task: ${task.title}',
      task.description ?? 'Running for $minutes min',
      details,
    );
  }

  Future<void> updateTaskNotification(TaskEntity task) async {
    await showTaskNotification(task);
  }

  Future<void> cancelTaskNotification() async {
    await _notifications.cancel(_taskNotificationId);
  }
}
