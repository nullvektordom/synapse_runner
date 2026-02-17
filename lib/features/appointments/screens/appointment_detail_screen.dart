import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/appointment_entity.dart';
import '../providers/appointment_provider.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  final int appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(appointmentStreamProvider(appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment'),
        actions: [
          apptAsync.maybeWhen(
            data: (appt) => appt != null
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        context.go('/appointments/$appointmentId/edit'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: apptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (appt) {
          if (appt == null) {
            return const Center(child: Text('Appointment not found'));
          }
          return _AppointmentDetail(appointment: appt);
        },
      ),
    );
  }
}

class _AppointmentDetail extends ConsumerWidget {
  final AppointmentEntity appointment;

  const _AppointmentDetail({required this.appointment});

  String _tierLabel(int minutes) {
    if (minutes >= 1440) return '24 hours before';
    if (minutes >= 60) return '1 hour before';
    return '15 minutes before';
  }

  /// A tier has "fired" if we're past the time it was supposed to fire.
  bool _tierHasFired(int tierMinutes) {
    final tierTime =
        appointment.dateTime.subtract(Duration(minutes: tierMinutes));
    return DateTime.now().isAfter(tierTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appointmentNotifierProvider.notifier);
    final now = DateTime.now();
    final isPast =
        appointment.isCompleted || appointment.dateTime.isBefore(now);
    final dateStr =
        DateFormat('EEEE, d MMMM yyyy').format(appointment.dateTime);
    final timeStr = DateFormat('HH:mm').format(appointment.dateTime);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (appointment.isCompleted)
                      Chip(
                        label: const Text('Complete'),
                        avatar: const Icon(Icons.check, size: 16),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(dateStr),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 8),
                    Text(timeStr),
                  ],
                ),
                if (appointment.description != null &&
                    appointment.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(appointment.description!)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Notification tiers
        Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...appointment.notificationTiers.map(
          (tier) => _TierRow(
            tier: tier,
            appointment: appointment,
            hasFired: _tierHasFired(tier.tierMinutes),
            label: _tierLabel(tier.tierMinutes),
            onConfirm: isPast
                ? null
                : () => notifier.confirmNotificationTier(
                      appointment.id,
                      tier.tierMinutes,
                    ),
          ),
        ),
        const SizedBox(height: 24),

        // Complete button
        if (!appointment.isCompleted)
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Mark as complete?'),
                  content:
                      const Text('This will cancel all pending notifications.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Complete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await notifier.completeAppointment(appointment.id);
                if (context.mounted) context.go('/appointments');
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as Complete'),
          ),
      ],
    );
  }
}

class _TierRow extends StatelessWidget {
  final NotificationTierState tier;
  final AppointmentEntity appointment;
  final bool hasFired;
  final String label;
  final VoidCallback? onConfirm;

  const _TierRow({
    required this.tier,
    required this.appointment,
    required this.hasFired,
    required this.label,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final fireTime =
        appointment.dateTime.subtract(Duration(minutes: tier.tierMinutes));
    final fireTimeStr = DateFormat('d MMM, HH:mm').format(fireTime);

    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    if (tier.confirmed) {
      statusColor = Theme.of(context).colorScheme.secondary;
      statusIcon = Icons.check_circle;
      statusText = 'Confirmed';
    } else if (hasFired) {
      statusColor = Theme.of(context).colorScheme.tertiary;
      statusIcon = Icons.notifications_active;
      statusText = 'Pending confirmation';
    } else {
      statusColor = Theme.of(context).colorScheme.outline;
      statusIcon = Icons.schedule;
      statusText = 'Scheduled for $fireTimeStr';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(label),
        subtitle: Text(statusText),
        trailing: hasFired && !tier.confirmed && onConfirm != null
            ? FilledButton.tonal(
                onPressed: onConfirm,
                child: const Text('Confirm'),
              )
            : null,
      ),
    );
  }
}
