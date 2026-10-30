String dayKey(DateTime d) => d.toIso8601String().substring(0, 10);

class Activity {
  final int? id;
  final String type;
  final DateTime date;
  final int minutes;
  final int calories;
  final int steps;

  const Activity({
    this.id,
    required this.type,
    required this.date,
    required this.minutes,
    required this.calories,
    this.steps = 0,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type,
        'date': dayKey(date),
        'minutes': minutes,
        'calories': calories,
        'steps': steps,
      };

  factory Activity.fromMap(Map<String, Object?> m) => Activity(
        id: m['id'] as int?,
        type: m['type'] as String,
        date: DateTime.parse(m['date'] as String),
        minutes: m['minutes'] as int,
        calories: m['calories'] as int,
        steps: m['steps'] as int,
      );
}
