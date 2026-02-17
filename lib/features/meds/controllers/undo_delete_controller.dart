import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/alarm_service.dart';
import '../models/medication_entity.dart';
import '../providers/medication_provider.dart';

final undoDeleteControllerProvider = Provider<UndoDeleteController>((ref) {
  return UndoDeleteController(ref);
});

class UndoDeleteController {
  UndoDeleteController(this.ref);

  final Ref ref;

  Future<void> handleDelete({
    required BuildContext context,
    required MedicationEntity medication,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final repository = await ref.read(medicationRepositoryProvider.future);

    // Cancel alarms and delete immediately for optimistic UI
    await AlarmService.cancelAlarmsForMedication(medication.id);
    await repository.deleteMedication(medication.id);

    // Ensure no stacked SnackBars
    messenger.clearSnackBars();

    // Show SnackBar with undo option
    // Note: SnackBars with actions persist indefinitely by default,
    // so we manually hide it after the duration using a Timer
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('${medication.medName} deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // Undo = reinsert the medication and reschedule alarms
            await repository.createMedication(medication);
            await AlarmService.scheduleAlarmsForMedication(medication);
          },
        ),
      ),
    );

    // Manually dismiss after 4 seconds since SnackBars with actions persist
    Timer(const Duration(seconds: 4), () {
      controller.close();
    });
  }
}
