import 'package:flutter/material.dart';
import '../db/database.dart';
import '../models/activity.dart';
import 'add_activity_screen.dart';

enum Metric { steps, calories, minutes }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const goals = {
    Metric.steps: 10000,
    Metric.calories: 500,
    Metric.minutes: 45,
  };

  List<Activity> _items = [];
  Metric _metric = Metric.steps;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await AppDatabase.instance.all();
      if (mounted) setState(() {
        _items = items;
        _loadError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = 'Could not load activities: $error');
    }
  }

  int _value(Activity a, Metric m) => switch (m) {
        Metric.steps => a.steps,
        Metric.calories => a.calories,
        Metric.minutes => a.minutes,
      };

  int _total(DateTime day, Metric m) => _items
      .where((a) => dayKey(a.date) == dayKey(day))
      .fold(0, (s, a) => s + _value(a, m));

  Future<void> _add() async {
    final added = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const AddActivityScreen()));
    if (added == true) _load();
  }

  Future<void> _delete(Activity a) async {
    await AppDatabase.instance.delete(a.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Stride')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Log activity'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _todayCard(today),
            const SizedBox(height: 12),
            _weekCard(today),
            const SizedBox(height: 12),
            _recentCard(),
          ],
        ),
      ),
    );
  }

  Widget _todayCard(DateTime today) {
    Widget row(String label, Metric m, String unit) {
      final v = _total(today, m);
      final g = goals[m]!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                Text('$v / $g $unit',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                  value: (v / g).clamp(0, 1).toDouble(), minHeight: 10),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today', style: Theme.of(context).textTheme.titleMedium),
            row('Steps', Metric.steps, ''),
            row('Calories burned', Metric.calories, 'kcal'),
            row('Active minutes', Metric.minutes, 'min'),
          ],
        ),
      ),
    );
  }

  Widget _weekCard(DateTime today) {
    final days = List.generate(
        7, (i) => today.subtract(Duration(days: 6 - i)));
    final vals = days.map((d) => _total(d, _metric)).toList();
    final maxV = [...vals, goals[_metric]! ~/ 2, 1].reduce((a, b) => a > b ? a : b);
    final scheme = Theme.of(context).colorScheme;
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This week', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<Metric>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: Metric.steps, label: Text('Steps')),
                ButtonSegment(value: Metric.calories, label: Text('Calories')),
                ButtonSegment(value: Metric.minutes, label: Text('Minutes')),
              ],
              selected: {_metric},
              onSelectionChanged: (s) => setState(() => _metric = s.first),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(vals[i] == 0 ? '' : '${vals[i]}',
                              style: const TextStyle(fontSize: 10)),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            height: 2 + 110 * vals[i] / maxV,
                            decoration: BoxDecoration(
                              color: i == 6 ? scheme.tertiary : scheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(names[days[i].weekday - 1],
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Recent activity',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_loadError!),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No activity yet. Tap "Log activity" to add your first one.'),
              ),
            for (final a in _items.take(15))
              ListTile(
                title: Text(a.type),
                subtitle: Text(
                    '${dayKey(a.date)} - ${a.minutes} min, ${a.calories} kcal'
                    '${a.steps > 0 ? ', ${a.steps} steps' : ''}'),
                trailing: IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(a),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
