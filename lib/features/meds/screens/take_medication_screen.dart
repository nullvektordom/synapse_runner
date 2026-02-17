import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import '../models/medication_entity.dart';
import '../providers/medication_provider.dart';

class TakeMedicationScreen extends ConsumerWidget {
  const TakeMedicationScreen({super.key});

  bool _isDoseTakenToday(MedicationEntity med, int scheduledMinute) {
    final now = DateTime.now();
    return med.takenDoses.any((d) =>
        d.scheduledMinute == scheduledMinute &&
        d.takenAt != null &&
        d.takenAt!.year == now.year &&
        d.takenAt!.month == now.month &&
        d.takenAt!.day == now.day);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Medications'),
      ),
      body: medicationsAsync.when(
        data: (medications) {
          if (medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No medications scheduled',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          // Count total and taken time slots across all meds
          int totalSlots = 0;
          int takenSlots = 0;
          for (final med in medications) {
            for (final minute in med.scheduledTimesMinutes) {
              totalSlots++;
              if (_isDoseTakenToday(med, minute)) {
                takenSlots++;
              }
            }
          }
          final allTaken = takenSlots == totalSlots && totalSlots > 0;

          return Column(
            children: [
              // Header with date
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),

              // Progress counter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$takenSlots of $totalSlots taken',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Medication cards with per-time-slot checkboxes
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    final sortedMinutes =
                        List<int>.from(med.scheduledTimesMinutes)..sort();

                    return Card(
                      key: ValueKey(med.id),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card header
                            ListTile(
                              leading: Icon(
                                med.isVital
                                    ? Icons.emergency
                                    : Icons.medication,
                                color: med.isVital
                                    ? Theme.of(context).colorScheme.tertiary
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                med.medName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(med.dosage),
                            ),
                            const Divider(height: 1),
                            // One row per time slot
                            for (final minute in sortedMinutes)
                              _TimeSlotRow(
                                med: med,
                                scheduledMinute: minute,
                                isTaken: _isDoseTakenToday(med, minute),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // "All done" card
              if (allTaken)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'All medications taken for today',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _TimeSlotRow extends ConsumerWidget {
  final MedicationEntity med;
  final int scheduledMinute;
  final bool isTaken;

  const _TimeSlotRow({
    required this.med,
    required this.scheduledMinute,
    required this.isTaken,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = scheduledMinute.toTimeString();

    return CheckboxListTile(
      value: isTaken,
      onChanged: isTaken
          ? null
          : (value) async {
              if (value == true) {
                ref
                    .read(medicationNotifierProvider.notifier)
                    .markDoseAsTaken(med.id, scheduledMinute);
                if (await Vibration.hasVibrator()) {
                  Vibration.vibrate(duration: 50);
                }
              }
            },
      title: Text(
        timeStr,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              decoration: isTaken ? TextDecoration.lineThrough : null,
            ),
      ),
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
    );
  }
}
