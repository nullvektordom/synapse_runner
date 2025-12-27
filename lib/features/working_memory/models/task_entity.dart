import 'package:isar/isar.dart';

part 'task_entity.g.dart';

@collection
class TaskEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String title;

  String? description;

  late DateTime startTime;

  int? durationMinutes;

  int reminderFrequencyMinutes;

  bool isCompleted;

  TaskEntity({
    required this.title,
    this.description,
    required this.startTime,
    this.durationMinutes,
    this.reminderFrequencyMinutes = 5,
    this.isCompleted = false,
  });
}
