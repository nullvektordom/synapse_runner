import 'package:isar/isar.dart';

part 'appointment_entity.g.dart';

/// Notification tiers: minutes before appointment (24h, 1h, 15min)
const List<int> kAppointmentTierMinutes = [1440, 60, 15];

@embedded
class NotificationTierState {
  int tierMinutes = 0; // 1440=24h, 60=1h, 15=15min
  bool confirmed = false;
  DateTime? confirmedAt;
}

@collection
class AppointmentEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String title;

  String? description;

  @Index()
  late DateTime dateTime;

  bool isCompleted = false;

  /// Confirmation state for each notification tier (24h, 1h, 15min)
  List<NotificationTierState> notificationTiers = [];
}
