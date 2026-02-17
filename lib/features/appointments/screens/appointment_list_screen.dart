import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/appointment_entity.dart';
import '../providers/appointment_provider.dart';

class AppointmentListScreen extends ConsumerWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (appointments) {
          final now = DateTime.now();
          final upcoming = appointments
              .where((a) => !a.isCompleted && a.dateTime.isAfter(now))
              .toList();
          final past = appointments
              .where((a) => a.isCompleted || a.dateTime.isBefore(now))
              .toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_available, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add one',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(title: 'Upcoming (${upcoming.length})'),
                ...upcoming.map((a) => _AppointmentTile(appointment: a)),
              ],
              if (past.isNotEmpty) ...[
                _SectionHeader(title: 'Past (${past.length})'),
                ...past.map((a) => _AppointmentTile(appointment: a)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/appointments/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _AppointmentTile extends ConsumerWidget {
  final AppointmentEntity appointment;

  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isPast =
        appointment.isCompleted || appointment.dateTime.isBefore(now);
    final dateStr = DateFormat('EEE d MMM').format(appointment.dateTime);
    final timeStr = DateFormat('HH:mm').format(appointment.dateTime);

    // Count unconfirmed tiers that have already fired
    final pendingConfirmations = appointment.notificationTiers
        .where((t) =>
            !t.confirmed &&
            appointment.dateTime
                .subtract(Duration(minutes: t.tierMinutes))
                .isBefore(now))
        .length;

    return Dismissible(
      key: ValueKey(appointment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete appointment?'),
            content: Text('Remove "${appointment.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref
            .read(appointmentNotifierProvider.notifier)
            .deleteAppointment(appointment.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${appointment.title}" deleted')),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPast
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            appointment.isCompleted ? Icons.check : Icons.event,
            color: isPast
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          appointment.title,
          style: isPast
              ? const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                )
              : null,
        ),
        subtitle: Text(
          appointment.description != null && appointment.description!.isNotEmpty
              ? '$dateStr at $timeStr · ${appointment.description}'
              : '$dateStr at $timeStr',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: pendingConfirmations > 0
            ? Badge(
                label: Text('$pendingConfirmations'),
                child: const Icon(Icons.notifications_active),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.go('/appointments/${appointment.id}'),
      ),
    );
  }
}
