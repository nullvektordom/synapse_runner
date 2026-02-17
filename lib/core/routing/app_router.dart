import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/working_memory/screens/task_screen.dart';
import '../../features/working_memory/widgets/current_task_banner.dart';
import '../../features/meds/screens/medication_list_screen.dart';
import '../../features/meds/screens/take_medication_screen.dart';
import '../../features/appointments/screens/appointment_list_screen.dart';
import '../../features/appointments/screens/add_appointment_screen.dart';
import '../../features/appointments/screens/appointment_detail_screen.dart';
import '../../features/appointments/providers/appointment_provider.dart';

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
      GoRoute(
        path: '/take-meds',
        name: 'take-meds',
        builder: (context, state) => const TakeMedicationScreen(),
      ),
      GoRoute(
        path: '/appointments',
        name: 'appointments',
        builder: (context, state) => const AppointmentListScreen(),
      ),
      GoRoute(
        path: '/appointments/add',
        name: 'appointments-add',
        builder: (context, state) => const AddAppointmentScreen(),
      ),
      GoRoute(
        path: '/appointments/:id',
        name: 'appointment-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AppointmentDetailScreen(appointmentId: id);
        },
      ),
      GoRoute(
        path: '/appointments/:id/edit',
        name: 'appointment-edit',
        builder: (context, state) {
          // Pass the appointment ID; detail screen navigates here so we
          // read the entity directly in the widget via a FutureBuilder.
          final id = int.parse(state.pathParameters['id']!);
          return _AppointmentEditLoader(appointmentId: id);
        },
      ),
    ],
  );
}

/// Loads the appointment entity then forwards to AddAppointmentScreen in edit mode.
class _AppointmentEditLoader extends ConsumerWidget {
  final int appointmentId;
  const _AppointmentEditLoader({required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(appointmentStreamProvider(appointmentId));
    return apptAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (appt) => appt != null
          ? AddAppointmentScreen(existing: appt)
          : const Scaffold(body: Center(child: Text('Appointment not found'))),
    );
  }
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
                              leading: const Icon(Icons.event),
                              title: const Text('Appointments'),
                              subtitle: const Text('Never miss an appointment'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.go('/appointments'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.medication),
                              title: const Text('Medications'),
                              subtitle: const Text('View medication schedule'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.go('/medications'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.checklist),
                              title: const Text('Take Medications'),
                              subtitle: const Text('Check off today\'s meds'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.go('/take-meds'),
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
