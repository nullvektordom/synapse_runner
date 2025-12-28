import 'package:isar/isar.dart';
import '../../../core/database/isar_service.dart';
import '../models/medication_entity.dart';

class MedicationRepository {
  final Isar _isar;

  MedicationRepository(this._isar);

  static Future<MedicationRepository> create() async {
    final isar = await IsarService.instance;
    final repo = MedicationRepository(isar);
    await repo._seedMockDataIfEmpty();
    return repo;
  }

  // TEMPORARY: Seed mock data for smoke testing
  Future<void> _seedMockDataIfEmpty() async {
    final count = await _isar.medicationEntitys.count();
    if (count == 0) {
      await _isar.writeTxn(() async {
        // Mock 1: Vitamin C, 500mg, 08:00
        final now = DateTime.now();
        final vitaminC = MedicationEntity(
          medName: 'Vitamin C',
          dosage: '500mg',
          scheduledTime: DateTime(now.year, now.month, now.day, 8, 0),
          isVital: false,
        );

        // Mock 2: Omega 3, 1000mg, 20:00, isVital: true
        final omega3 = MedicationEntity(
          medName: 'Omega 3',
          dosage: '1000mg',
          scheduledTime: DateTime(now.year, now.month, now.day, 20, 0),
          isVital: true,
        );

        await _isar.medicationEntitys.put(vitaminC);
        await _isar.medicationEntitys.put(omega3);
      });
    }
  }

  // Get all medications
  Future<List<MedicationEntity>> getAllMedications() async {
    return await _isar.medicationEntitys
        .where()
        .sortByScheduledTime()
        .findAll();
  }

  // Create a new medication
  Future<int> createMedication(MedicationEntity medication) async {
    return await _isar.writeTxn(() async {
      return await _isar.medicationEntitys.put(medication);
    });
  }

  // Update a medication
  Future<int> updateMedication(MedicationEntity medication) async {
    return await _isar.writeTxn(() async {
      return await _isar.medicationEntitys.put(medication);
    });
  }

  // Delete a medication
  Future<bool> deleteMedication(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.medicationEntitys.delete(id);
    });
  }

  // Watch all medications (reactive stream)
  Stream<List<MedicationEntity>> watchAllMedications() {
    return _isar.medicationEntitys
        .where()
        .sortByScheduledTime()
        .watch(fireImmediately: true);
  }

  // Get a single medication by ID
  Future<MedicationEntity?> getMedication(int id) async {
    return await _isar.medicationEntitys.get(id);
  }
}
