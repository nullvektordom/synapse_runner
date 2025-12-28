import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_entity.dart';
import '../repositories/medication_repository.dart';

// Medication repository provider
final medicationRepositoryProvider = FutureProvider<MedicationRepository>((ref) async {
  return await MedicationRepository.create();
});

// All medications provider (stream)
final medicationsStreamProvider = StreamProvider<List<MedicationEntity>>((ref) async* {
  final repository = await ref.watch(medicationRepositoryProvider.future);
  yield* repository.watchAllMedications();
});
