import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_providers.dart';
import '../widgets/current_task_banner.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task title',
                hintText: 'What are you doing?',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add more details...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty) {
                ref.read(taskNotifierProvider.notifier).createTask(
                      title: _titleController.text,
                      description: _descriptionController.text.isEmpty
                          ? null
                          : _descriptionController.text,
                    );
                _titleController.clear();
                _descriptionController.clear();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incompleteTasksAsync = ref.watch(incompleteTasksProvider);
    final currentTaskAsync = ref.watch(currentTaskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Task'),
      ),
      body: Column(
        children: [
          const CurrentTaskBanner(),
          Expanded(
            child: incompleteTasksAsync.when(
              data: (tasks) {
                // Filter out the current task from the list (already shown in banner)
                final currentTask = currentTaskAsync.value;
                final otherTasks = currentTask != null
                    ? tasks.where((t) => t.id != currentTask.id).toList()
                    : tasks;

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active tasks',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create a new task',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  );
                }

                if (otherTasks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Your current task is shown above.\nCreate another task to see more here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: otherTasks.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final task = otherTasks[index];
                    final duration = DateTime.now().difference(task.startTime);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.task),
                        title: Text(task.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.description != null) Text(task.description!),
                            const SizedBox(height: 4),
                            Text(
                              'Started ${duration.inMinutes} min ago',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () {
                            ref
                                .read(taskNotifierProvider.notifier)
                                .completeTask(task.id);
                          },
                        ),
                        isThreeLine: task.description != null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
