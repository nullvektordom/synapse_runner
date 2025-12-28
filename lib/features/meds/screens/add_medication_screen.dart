import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/medication_entity.dart';
import '../providers/medication_provider.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  final MedicationEntity? medication;

  const AddMedicationScreen({super.key, this.medication});

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medNameController = TextEditingController();
  final _dosageController = TextEditingController();

  late TimeOfDay _selectedTime;
  late bool _isVital;
  bool _isSaving = false;

  bool get _isEditMode => widget.medication != null;

  @override
  void initState() {
    super.initState();

    // Pre-fill fields if in edit mode
    if (_isEditMode) {
      final med = widget.medication!;
      _medNameController.text = med.medName;
      _dosageController.text = med.dosage;
      _selectedTime = TimeOfDay(
        hour: med.scheduledTime.hour,
        minute: med.scheduledTime.minute,
      );
      _isVital = med.isVital;
    } else {
      _selectedTime = TimeOfDay.now();
      _isVital = false;
    }
  }

  @override
  void dispose() {
    _medNameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = await ref.read(medicationRepositoryProvider.future);

      // Convert TimeOfDay to DateTime
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (_isEditMode) {
        // Update existing medication
        final updatedMedication = MedicationEntity(
          medName: _medNameController.text.trim(),
          dosage: _dosageController.text.trim(),
          scheduledTime: scheduledDateTime,
          isVital: _isVital,
          lastTakenTimestamp: widget.medication!.lastTakenTimestamp,
        );
        updatedMedication.id = widget.medication!.id;
        await repository.updateMedication(updatedMedication);
      } else {
        // Create new medication
        final medication = MedicationEntity(
          medName: _medNameController.text.trim(),
          dosage: _dosageController.text.trim(),
          scheduledTime: scheduledDateTime,
          isVital: _isVital,
        );
        await repository.createMedication(medication);
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
    final timeFormat = DateFormat('HH:mm');
    final displayTime = DateTime(2000, 1, 1, _selectedTime.hour, _selectedTime.minute);

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
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Scheduled Time'),
                subtitle: Text(timeFormat.format(displayTime)),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectTime(context),
              ),
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
