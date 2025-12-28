import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task_entity.dart';
import '../../../core/services/foreground_service.dart';

class TaskNotificationService {
  static const String _channelId = 'current_task_channel';
  static const String _channelName = 'Current Task';
  static const String _channelDescription = 'Shows your current active task';

  final FlutterLocalNotificationsPlugin _notifications;
  bool _isServiceRunning = false;

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

    // Always use startService - it handles both starting and updating
    // This ensures the service is restarted after app restart
    await ForegroundService.startService(
      taskTitle: task.title,
      taskDescription: task.description ?? '',
      durationMinutes: minutes,
    );
    _isServiceRunning = true;
  }

  Future<void> updateTaskNotification(TaskEntity task) async {
    await showTaskNotification(task);
  }

  Future<void> cancelTaskNotification() async {
    if (_isServiceRunning) {
      await ForegroundService.stopService();
      _isServiceRunning = false;
    }
  }
}
