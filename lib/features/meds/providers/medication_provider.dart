import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/alarm_service.dart';
import '../models/medication_entity.dart';
import '../repositories/medication_repository.dart';

// Medication repository provider
final medicationRepositoryProvider =
    FutureProvider<MedicationRepository>((ref) async {
  return await MedicationRepository.create();
});

// All medications provider (stream)
final medicationsStreamProvider =
    StreamProvider<List<MedicationEntity>>((ref) async* {
  final repository = await ref.watch(medicationRepositoryProvider.future);
  yield* repository.watchAllMedications();
});

// Medication notifier for mutations (coordinates alarms with CRUD)
final medicationNotifierProvider =
    StateNotifierProvider<MedicationNotifier, AsyncValue<void>>((ref) {
  return MedicationNotifier(ref);
});

class MedicationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  MedicationNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> markDoseAsTaken(int medId, int scheduledMinute) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(medicationRepositoryProvider.future);
      await repository.markDoseAsTaken(medId, scheduledMinute);
    });
  }

  Future<void> createMedication(MedicationEntity med) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(medicationRepositoryProvider.future);
      final id = await repository.createMedication(med);
      med.id = id;
      await AlarmService.scheduleAlarmsForMedication(med);
    });
  }

  Future<void> updateMedication(MedicationEntity med) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(medicationRepositoryProvider.future);
      await AlarmService.cancelAlarmsForMedication(med.id);
      await repository.updateMedication(med);
      await AlarmService.scheduleAlarmsForMedication(med);
    });
  }

  Future<void> deleteMedication(int medId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(medicationRepositoryProvider.future);
      await AlarmService.cancelAlarmsForMedication(medId);
      await repository.deleteMedication(medId);
    });
  }
}
