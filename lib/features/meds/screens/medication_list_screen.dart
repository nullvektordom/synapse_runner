import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_entity.dart';
import '../providers/medication_provider.dart';
import 'package:intl/intl.dart';

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
      ),
      body: medicationsAsync.when(
        data: (medications) {
          if (medications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
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
              return _MedicationCard(medication: med);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final MedicationEntity medication;

  const _MedicationCard({required this.medication});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final scheduledTime = timeFormat.format(medication.scheduledTime);

    String lastTakenText = 'Never taken';
    if (medication.lastTakenTimestamp != null) {
      final lastTaken = DateFormat('MMM d, HH:mm').format(medication.lastTakenTimestamp!);
      lastTakenText = 'Last: $lastTaken';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Text('Scheduled: $scheduledTime'),
            const SizedBox(height: 4),
            Text(
              lastTakenText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
