import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'medication_entity.g.dart';

@embedded
class TakenDose {
  int scheduledMinute = 0; // minutes since midnight (e.g., 480 = 08:00)
  DateTime? takenAt;
}

@collection
class MedicationEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String medName;

  late String dosage;

  // Legacy: kept for sort ordering (set to first scheduled time)
  late DateTime scheduledTime;

  // Multiple daily alarm times as minutes since midnight
  List<int> scheduledTimesMinutes = [];

  // Legacy: single taken timestamp (kept for backward compat)
  DateTime? lastTakenTimestamp;

  // Per-time-slot taken records
  List<TakenDose> takenDoses = [];

  bool isVital;

  MedicationEntity({
    required this.medName,
    required this.dosage,
    required this.scheduledTime,
    this.scheduledTimesMinutes = const [],
    this.lastTakenTimestamp,
    this.takenDoses = const [],
    this.isVital = false,
  });
}

// Helpers for minutes-since-midnight <-> TimeOfDay conversion
extension MinutesToTime on int {
  TimeOfDay toTimeOfDay() => TimeOfDay(hour: this ~/ 60, minute: this % 60);

  String toTimeString() {
    final h = (this ~/ 60).toString().padLeft(2, '0');
    final m = (this % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

extension TimeOfDayToMinutes on TimeOfDay {
  int toMinutesSinceMidnight() => hour * 60 + minute;
}
