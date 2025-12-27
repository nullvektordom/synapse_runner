import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_entity.dart';
import '../services/task_notification_service.dart';
import 'task_providers.dart';

final taskNotificationServiceProvider = Provider<TaskNotificationService>((ref) {
  final notifications = FlutterLocalNotificationsPlugin();
  return TaskNotificationService(notifications);
});

final taskNotificationWatcherProvider = Provider<TaskNotificationWatcher>((ref) {
  return TaskNotificationWatcher(ref);
});

class TaskNotificationWatcher {
  final Ref ref;

  TaskNotificationWatcher(this.ref) {
    _watchCurrentTask();
  }

  void _watchCurrentTask() {
    ref.listen<AsyncValue<TaskEntity?>>(
      currentTaskProvider,
      (previous, next) {
        next.whenData((task) async {
          final service = ref.read(taskNotificationServiceProvider);

          if (task != null) {
            // Show or update notification for current task
            await service.showTaskNotification(task);
          } else {
            // Cancel notification when no current task
            await service.cancelTaskNotification();
          }
        });
      },
    );
  }
}
