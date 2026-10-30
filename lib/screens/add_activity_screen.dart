import 'package:flutter/material.dart';
import '../db/database.dart';
import '../models/activity.dart';

const activityTypes = [
  'Walking', 'Running', 'Cycling', 'Strength', 'Yoga', 'Swimming', 'Other'
];

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _form = GlobalKey<FormState>();
  final _minutes = TextEditingController();
  final _calories = TextEditingController();
  final _steps = TextEditingController();
  String _type = activityTypes.first;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _minutes.dispose();
    _calories.dispose();
    _steps.dispose();
    super.dispose();
  }

  String? _required(String? v) {
    final n = int.tryParse(v ?? '');
    return (n == null || n < 0) ? 'Enter a number' : null;
  }

  String? _optional(String? v) =>
      (v == null || v.isEmpty) ? null : _required(v);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AppDatabase.instance.insert(Activity(
        type: _type,
        date: _date,
        minutes: int.parse(_minutes.text),
        calories: int.parse(_calories.text),
        steps: int.tryParse(_steps.text) ?? 0,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save activity: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log activity')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                  labelText: 'Type', border: OutlineInputBorder()),
              items: [
                for (final t in activityTypes)
                  DropdownMenuItem(value: t, child: Text(t))
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(dayKey(_date)),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder()),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _calories,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Calories burned', border: OutlineInputBorder()),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _steps,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Steps (optional)', border: OutlineInputBorder()),
              validator: _optional,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add activity'),
            ),
          ],
        ),
      ),
    );
  }
}
