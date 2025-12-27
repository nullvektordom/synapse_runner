import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_entity.dart';
import '../repositories/task_repository.dart';

// Task repository provider
final taskRepositoryProvider = FutureProvider<TaskRepository>((ref) async {
  return await TaskRepository.create();
});

// Current active task provider (stream)
final currentTaskProvider = StreamProvider<TaskEntity?>((ref) async* {
  final repository = await ref.watch(taskRepositoryProvider.future);
  yield* repository.watchCurrentTask();
});

// All incomplete tasks provider (stream)
final incompleteTasksProvider = StreamProvider<List<TaskEntity>>((ref) async* {
  final repository = await ref.watch(taskRepositoryProvider.future);
  yield* repository.watchIncompleteTasks();
});

// Task notifier for actions (create, update, delete, complete)
final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<void>>((ref) {
  return TaskNotifier(ref);
});

class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  TaskNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> createTask({
    required String title,
    String? description,
    int? durationMinutes,
    int reminderFrequencyMinutes = 5,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(taskRepositoryProvider.future);
      final task = TaskEntity(
        title: title,
        description: description,
        startTime: DateTime.now(),
        durationMinutes: durationMinutes,
        reminderFrequencyMinutes: reminderFrequencyMinutes,
      );
      await repository.createTask(task);
    });
  }

  Future<void> updateTask(TaskEntity task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(taskRepositoryProvider.future);
      await repository.updateTask(task);
    });
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(taskRepositoryProvider.future);
      await repository.deleteTask(id);
    });
  }

  Future<void> completeTask(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(taskRepositoryProvider.future);
      await repository.completeTask(id);
    });
  }
}
