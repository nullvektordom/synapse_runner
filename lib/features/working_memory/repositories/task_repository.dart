import 'package:isar/isar.dart';
import '../../../core/database/isar_service.dart';
import '../models/task_entity.dart';

class TaskRepository {
  final Isar _isar;

  TaskRepository(this._isar);

  static Future<TaskRepository> create() async {
    final isar = await IsarService.instance;
    return TaskRepository(isar);
  }

  // Get current active task
  Future<TaskEntity?> getCurrentTask() async {
    return await _isar.taskEntitys
        .filter()
        .isCompletedEqualTo(false)
        .sortByStartTimeDesc()
        .findFirst();
  }

  // Get all tasks
  Future<List<TaskEntity>> getAllTasks() async {
    return await _isar.taskEntitys.where().findAll();
  }

  // Get incomplete tasks
  Future<List<TaskEntity>> getIncompleteTasks() async {
    return await _isar.taskEntitys
        .filter()
        .isCompletedEqualTo(false)
        .sortByStartTimeDesc()
        .findAll();
  }

  // Create a new task
  Future<int> createTask(TaskEntity task) async {
    return await _isar.writeTxn(() async {
      return await _isar.taskEntitys.put(task);
    });
  }

  // Update a task
  Future<int> updateTask(TaskEntity task) async {
    return await _isar.writeTxn(() async {
      return await _isar.taskEntitys.put(task);
    });
  }

  // Delete a task
  Future<bool> deleteTask(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.taskEntitys.delete(id);
    });
  }

  // Mark task as completed
  Future<void> completeTask(int id) async {
    await _isar.writeTxn(() async {
      final task = await _isar.taskEntitys.get(id);
      if (task != null) {
        task.isCompleted = true;
        await _isar.taskEntitys.put(task);
      }
    });
  }

  // Watch current task (reactive stream)
  Stream<TaskEntity?> watchCurrentTask() {
    return _isar.taskEntitys
        .filter()
        .isCompletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((tasks) => tasks.isEmpty ? null : tasks.first);
  }

  // Watch all incomplete tasks
  Stream<List<TaskEntity>> watchIncompleteTasks() {
    return _isar.taskEntitys
        .filter()
        .isCompletedEqualTo(false)
        .watch(fireImmediately: true);
  }
}
