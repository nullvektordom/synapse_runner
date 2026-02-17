import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'core/database/isar_service.dart';
import 'core/providers/notification_provider.dart';
import 'core/routing/app_router.dart';
import 'core/services/permission_service.dart';
import 'core/services/alarm_service.dart';
import 'core/theme/app_theme.dart';
import 'features/meds/models/medication_entity.dart';
import 'features/appointments/models/appointment_entity.dart';
import 'features/appointments/services/appointment_alarm_service.dart';
import 'features/working_memory/providers/task_notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar database
  final isar = await IsarService.instance;

  // Initialize Alarm Service and reschedule per-medication alarms
  await AlarmService.initialize();
  final meds = await isar.medicationEntitys.where().findAll();
  await AlarmService.rescheduleAllAlarms(meds);

  // Reschedule appointment alarms
  final appointments = await isar.appointmentEntitys.where().findAll();
  await AppointmentAlarmService.rescheduleAllAppointments(appointments);

  // Request notification permissions (Android 13+)
  final permissionService = PermissionService();
  await permissionService.requestNotificationPermission();

  runApp(
    const ProviderScope(
      child: SynapseRunnerApp(),
    ),
  );
}

class SynapseRunnerApp extends ConsumerStatefulWidget {
  const SynapseRunnerApp({super.key});

  @override
  ConsumerState<SynapseRunnerApp> createState() => _SynapseRunnerAppState();
}

class _SynapseRunnerAppState extends ConsumerState<SynapseRunnerApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize general notification service
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize();

    // Initialize task notification service
    final taskNotificationService = ref.read(taskNotificationServiceProvider);
    await taskNotificationService.initialize();

    // Start watching for task changes to update notifications
    ref.read(taskNotificationWatcherProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Synapse Runner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
