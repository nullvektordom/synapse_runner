import 'package:isar/isar.dart';
import '../../../core/database/isar_service.dart';
import '../models/appointment_entity.dart';

class AppointmentRepository {
  final Isar _isar;

  AppointmentRepository(this._isar);

  static Future<AppointmentRepository> create() async {
    final isar = await IsarService.instance;
    return AppointmentRepository(isar);
  }

  // Create appointment — auto-initialises notification tier states
  Future<int> createAppointment(AppointmentEntity appointment) async {
    appointment.notificationTiers = kAppointmentTierMinutes
        .map((m) => NotificationTierState()..tierMinutes = m)
        .toList();
    return await _isar.writeTxn(() async {
      return await _isar.appointmentEntitys.put(appointment);
    });
  }

  // Update appointment
  Future<int> updateAppointment(AppointmentEntity appointment) async {
    return await _isar.writeTxn(() async {
      return await _isar.appointmentEntitys.put(appointment);
    });
  }

  // Delete appointment
  Future<bool> deleteAppointment(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.appointmentEntitys.delete(id);
    });
  }

  // Get single appointment
  Future<AppointmentEntity?> getAppointment(int id) async {
    return await _isar.appointmentEntitys.get(id);
  }

  // Get all appointments sorted by dateTime
  Future<List<AppointmentEntity>> getAllAppointments() async {
    return await _isar.appointmentEntitys.where().sortByDateTime().findAll();
  }

  // Mark a notification tier as confirmed (cancels re-notifies via provider)
  Future<void> confirmNotificationTier(int apptId, int tierMinutes) async {
    await _isar.writeTxn(() async {
      final appt = await _isar.appointmentEntitys.get(apptId);
      if (appt == null) return;
      final now = DateTime.now();
      for (final tier in appt.notificationTiers) {
        if (tier.tierMinutes == tierMinutes) {
          tier.confirmed = true;
          tier.confirmedAt = now;
          break;
        }
      }
      await _isar.appointmentEntitys.put(appt);
    });
  }

  // Mark appointment as complete
  Future<void> completeAppointment(int id) async {
    await _isar.writeTxn(() async {
      final appt = await _isar.appointmentEntitys.get(id);
      if (appt != null) {
        appt.isCompleted = true;
        await _isar.appointmentEntitys.put(appt);
      }
    });
  }

  // Reactive stream of all appointments
  Stream<List<AppointmentEntity>> watchAllAppointments() {
    return _isar.appointmentEntitys
        .where()
        .sortByDateTime()
        .watch(fireImmediately: true);
  }

  // Reactive stream of a single appointment
  Stream<AppointmentEntity?> watchAppointment(int id) {
    return _isar.appointmentEntitys.watchObject(id, fireImmediately: true);
  }
}
