import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_entity.dart';
import '../providers/medication_provider.dart';
import '../controllers/undo_delete_controller.dart';
import 'package:intl/intl.dart';
import 'add_medication_screen.dart';
import '../../../core/services/alarm_service.dart';

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_add),
            tooltip: 'Test Alarm (1 min)',
            onPressed: () async {
              await AlarmService.scheduleTestAlarm();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test alarm scheduled for 1 minute from now'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicationScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: medicationsAsync.when(
        data: (medications) {
          if (medications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No medications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final med = medications[index];
              return _MedicationCard(key: ValueKey(med.id), medication: med);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _MedicationCard extends ConsumerWidget {
  final MedicationEntity medication;

  const _MedicationCard({super.key, required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesStr = medication.scheduledTimesMinutes.isNotEmpty
        ? medication.scheduledTimesMinutes.map((m) => m.toTimeString()).join(', ')
        : DateFormat('HH:mm').format(medication.scheduledTime);

    return Dismissible(
      key: ValueKey(medication.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Medication'),
              content: Text('Delete ${medication.medName}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (_) async {
        if (!context.mounted) return;

        // Delegate all delete logic to controller
        // The controller will show a SnackBar with duration of 4 seconds
        // and handle the actual deletion after the SnackBar dismisses
        await ref.read(undoDeleteControllerProvider).handleDelete(
              context: context,
              medication: medication,
            );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(
            medication.isVital ? Icons.emergency : Icons.medication,
            color: medication.isVital ? Colors.orange : Colors.blue,
          ),
          title: Text(
            medication.medName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Dosage: ${medication.dosage}'),
              Text('Scheduled: $timesStr'),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddMedicationScreen(medication: medication),
              ),
            );
          },
        ),
      ),
    );
  }
}
