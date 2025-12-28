import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/working_memory/screens/task_screen.dart';
import '../../features/working_memory/widgets/current_task_banner.dart';
import '../../features/meds/screens/medication_list_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => const TaskScreen(),
      ),
      GoRoute(
        path: '/medications',
        name: 'medications',
        builder: (context, state) => const MedicationListScreen(),
      ),
    ],
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synapse Runner'),
      ),
      body: Column(
        children: [
          const CurrentTaskBanner(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.psychology,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ADHD Assistant',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sprint 1: Current Task Banner',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.task_alt),
                              title: const Text('Current Task'),
                              subtitle: const Text('Track what you\'re doing right now'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.go('/tasks'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.medication),
                              title: const Text('Medications'),
                              subtitle: const Text('View medication schedule'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.go('/medications'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
