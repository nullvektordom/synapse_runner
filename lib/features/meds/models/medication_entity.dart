import 'package:isar/isar.dart';

part 'medication_entity.g.dart';

@collection
class MedicationEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String medName;

  late String dosage;

  late DateTime scheduledTime;

  DateTime? lastTakenTimestamp;

  bool isVital;

  MedicationEntity({
    required this.medName,
    required this.dosage,
    required this.scheduledTime,
    this.lastTakenTimestamp,
    this.isVital = false,
  });
}
