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
    await repo._migrateToMultiTime();
    await repo._clearOldTakenDoses();
    return repo;
  }

  // TEMPORARY: Seed mock data for smoke testing
  Future<void> _seedMockDataIfEmpty() async {
    final count = await _isar.medicationEntitys.count();
    if (count == 0) {
      await _isar.writeTxn(() async {
        final now = DateTime.now();
        final vitaminC = MedicationEntity(
          medName: 'Vitamin C',
          dosage: '500mg',
          scheduledTime: DateTime(now.year, now.month, now.day, 8, 0),
          scheduledTimesMinutes: [480], // 08:00
          isVital: false,
        );

        final omega3 = MedicationEntity(
          medName: 'Omega 3',
          dosage: '1000mg',
          scheduledTime: DateTime(now.year, now.month, now.day, 8, 0),
          scheduledTimesMinutes: [480, 1200], // 08:00 and 20:00
          isVital: true,
        );

        await _isar.medicationEntitys.put(vitaminC);
        await _isar.medicationEntitys.put(omega3);
      });
    }
  }

  // Migrate legacy single-time records to multi-time format
  Future<void> _migrateToMultiTime() async {
    final allMeds = await _isar.medicationEntitys.where().findAll();
    final needsMigration =
        allMeds.where((m) => m.scheduledTimesMinutes.isEmpty).toList();

    if (needsMigration.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final med in needsMigration) {
        final minutes =
            med.scheduledTime.hour * 60 + med.scheduledTime.minute;
        med.scheduledTimesMinutes = [minutes];

        // Migrate lastTakenTimestamp to takenDoses if it's from today
        if (med.lastTakenTimestamp != null) {
          final taken = med.lastTakenTimestamp!;
          final now = DateTime.now();
          if (taken.year == now.year &&
              taken.month == now.month &&
              taken.day == now.day) {
            final dose = TakenDose()
              ..scheduledMinute = minutes
              ..takenAt = taken;
            med.takenDoses = [dose];
          }
        }

        await _isar.medicationEntitys.put(med);
      }
    });
  }

  // Remove stale takenDoses from previous days
  Future<void> _clearOldTakenDoses() async {
    final now = DateTime.now();
    final allMeds = await _isar.medicationEntitys.where().findAll();
    final needsCleaning = allMeds
        .where((m) => m.takenDoses.any((d) =>
            d.takenAt != null &&
            (d.takenAt!.year != now.year ||
                d.takenAt!.month != now.month ||
                d.takenAt!.day != now.day)))
        .toList();

    if (needsCleaning.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final med in needsCleaning) {
        med.takenDoses = med.takenDoses
            .where((d) =>
                d.takenAt != null &&
                d.takenAt!.year == now.year &&
                d.takenAt!.month == now.month &&
                d.takenAt!.day == now.day)
            .toList();
        await _isar.medicationEntitys.put(med);
      }
    });
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

  // Mark a specific dose as taken (per time slot)
  Future<void> markDoseAsTaken(int medId, int scheduledMinute) async {
    await _isar.writeTxn(() async {
      final med = await _isar.medicationEntitys.get(medId);
      if (med != null) {
        final now = DateTime.now();

        // Double-dose guard: check if already taken today for this time slot
        final alreadyTaken = med.takenDoses.any((d) =>
            d.scheduledMinute == scheduledMinute &&
            d.takenAt != null &&
            d.takenAt!.year == now.year &&
            d.takenAt!.month == now.month &&
            d.takenAt!.day == now.day);

        if (!alreadyTaken) {
          final dose = TakenDose()
            ..scheduledMinute = scheduledMinute
            ..takenAt = now;
          med.takenDoses = [...med.takenDoses, dose];
          med.lastTakenTimestamp = now;
          await _isar.medicationEntitys.put(med);
        }
      }
    });
  }
}
