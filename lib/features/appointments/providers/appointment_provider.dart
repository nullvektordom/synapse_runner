import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_entity.dart';
import '../repositories/appointment_repository.dart';
import '../services/appointment_alarm_service.dart';

// Appointment repository provider
final appointmentRepositoryProvider =
    FutureProvider<AppointmentRepository>((ref) async {
  return await AppointmentRepository.create();
});

// All appointments stream provider
final appointmentsStreamProvider =
    StreamProvider<List<AppointmentEntity>>((ref) async* {
  final repository = await ref.watch(appointmentRepositoryProvider.future);
  yield* repository.watchAllAppointments();
});

// Single appointment stream provider (for detail screen)
final appointmentStreamProvider =
    StreamProvider.family<AppointmentEntity?, int>((ref, id) async* {
  final repository = await ref.watch(appointmentRepositoryProvider.future);
  yield* repository.watchAppointment(id);
});

// Notifier for mutations — coordinates alarms with CRUD
final appointmentNotifierProvider =
    StateNotifierProvider<AppointmentNotifier, AsyncValue<void>>((ref) {
  return AppointmentNotifier(ref);
});

class AppointmentNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  AppointmentNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> createAppointment(AppointmentEntity appt) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(appointmentRepositoryProvider.future);
      final id = await repo.createAppointment(appt);
      appt.id = id;
      await AppointmentAlarmService.scheduleAlarmsForAppointment(appt);
    });
  }

  Future<void> updateAppointment(AppointmentEntity appt) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(appointmentRepositoryProvider.future);
      await AppointmentAlarmService.cancelAllAlarmsForAppointment(appt.id);
      await repo.updateAppointment(appt);
      if (!appt.isCompleted) {
        await AppointmentAlarmService.scheduleAlarmsForAppointment(appt);
      }
    });
  }

  Future<void> deleteAppointment(int apptId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(appointmentRepositoryProvider.future);
      await AppointmentAlarmService.cancelAllAlarmsForAppointment(apptId);
      await repo.deleteAppointment(apptId);
    });
  }

  Future<void> confirmNotificationTier(int apptId, int tierMinutes) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(appointmentRepositoryProvider.future);
      await repo.confirmNotificationTier(apptId, tierMinutes);
      await AppointmentAlarmService.cancelTierRenotifies(apptId, tierMinutes);
    });
  }

  Future<void> completeAppointment(int apptId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(appointmentRepositoryProvider.future);
      await AppointmentAlarmService.cancelAllAlarmsForAppointment(apptId);
      await repo.completeAppointment(apptId);
    });
  }
}
