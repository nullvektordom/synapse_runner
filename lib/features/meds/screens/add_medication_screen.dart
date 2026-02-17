import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_entity.dart';
import '../providers/medication_provider.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  final MedicationEntity? medication;

  const AddMedicationScreen({super.key, this.medication});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medNameController = TextEditingController();
  final _dosageController = TextEditingController();

  List<TimeOfDay> _scheduledTimes = [];
  late bool _isVital;
  bool _isSaving = false;

  bool get _isEditMode => widget.medication != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      final med = widget.medication!;
      _medNameController.text = med.medName;
      _dosageController.text = med.dosage;
      _scheduledTimes = med.scheduledTimesMinutes
          .map((m) => m.toTimeOfDay())
          .toList();
      _isVital = med.isVital;
    } else {
      _scheduledTimes = [];
      _isVital = false;
    }
  }

  @override
  void dispose() {
    _medNameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _addTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final alreadyExists = _scheduledTimes.any(
        (t) => t.hour == picked.hour && t.minute == picked.minute,
      );
      if (!alreadyExists) {
        setState(() {
          _scheduledTimes.add(picked);
          _scheduledTimes.sort((a, b) =>
              a.toMinutesSinceMidnight().compareTo(b.toMinutesSinceMidnight()));
        });
      }
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_scheduledTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one scheduled time')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final timesMinutes = _scheduledTimes
          .map((t) => t.toMinutesSinceMidnight())
          .toList()
        ..sort();

      final now = DateTime.now();
      final firstMinutes = timesMinutes.first;
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        firstMinutes ~/ 60,
        firstMinutes % 60,
      );

      if (_isEditMode) {
        final updated = MedicationEntity(
          medName: _medNameController.text.trim(),
          dosage: _dosageController.text.trim(),
          scheduledTime: scheduledDateTime,
          scheduledTimesMinutes: timesMinutes,
          isVital: _isVital,
          lastTakenTimestamp: widget.medication!.lastTakenTimestamp,
        );
        updated.id = widget.medication!.id;
        await ref
            .read(medicationNotifierProvider.notifier)
            .updateMedication(updated);
      } else {
        final med = MedicationEntity(
          medName: _medNameController.text.trim(),
          dosage: _dosageController.text.trim(),
          scheduledTime: scheduledDateTime,
          scheduledTimesMinutes: timesMinutes,
          isVital: _isVital,
        );
        await ref
            .read(medicationNotifierProvider.notifier)
            .createMedication(med);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving medication: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Medication' : 'Add Medication'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _medNameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                hintText: 'e.g., Vitamin D',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g., 500mg',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Scheduled Times',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _scheduledTimes.length; i++)
                  Chip(
                    label: Text(
                      _scheduledTimes[i]
                          .toMinutesSinceMidnight()
                          .toTimeString(),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _scheduledTimes.removeAt(i);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_alarm),
              label: const Text('Add Time'),
              onPressed: () => _addTime(context),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Mark as Vital'),
              subtitle: const Text('High priority medication'),
              value: _isVital,
              onChanged: (value) {
                setState(() {
                  _isVital = value;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMedication,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditMode ? 'Update Medication' : 'Save Medication',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
