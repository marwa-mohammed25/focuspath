/// كل الـ Models بتتحول لـ Map عشان نخزنها محلياً بسهولة.

class UserProfile {
  final String name;
  final String personalQuote;
  final int focusScore;

  const UserProfile({
    required this.name,
    this.personalQuote = '',
    this.focusScore = 0,
  });

  UserProfile copyWith({String? name, String? personalQuote, int? focusScore}) =>
      UserProfile(
        name: name ?? this.name,
        personalQuote: personalQuote ?? this.personalQuote,
        focusScore: focusScore ?? this.focusScore,
      );

  Map<String, dynamic> toMap() =>
      {'name': name, 'personalQuote': personalQuote, 'focusScore': focusScore};

  factory UserProfile.fromMap(Map m) => UserProfile(
    name: m['name'] ?? '',
    personalQuote: m['personalQuote'] ?? '',
    focusScore: m['focusScore'] ?? 0,
  );
}

// ---------- الأهداف الكبيرة (Dashboard) ----------

enum GoalCategory { study, work, health, language, other }

class Milestone {
  final String id;
  final String title;
  final bool done;

  const Milestone({required this.id, required this.title, this.done = false});

  Milestone toggled() => Milestone(id: id, title: title, done: !done);

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'done': done};

  factory Milestone.fromMap(Map m) =>
      Milestone(id: m['id'], title: m['title'], done: m['done'] ?? false);
}

class Goal {
  final String id;
  final String title;
  final String why; // ليه بدأتي؟
  final GoalCategory category;
  final DateTime? deadline;
  final DateTime createdAt;
  final List<Milestone> milestones;

  const Goal({
    required this.id,
    required this.title,
    required this.createdAt,
    this.why = '',
    this.category = GoalCategory.other,
    this.deadline,
    this.milestones = const [],
  });

  /// النسبة بتتحسب لوحدها من الخطوات اللي خلصتيها
  int get progress {
    if (milestones.isEmpty) return 0;
    final done = milestones.where((m) => m.done).length;
    return (done * 100 / milestones.length).round();
  }

  Goal copyWith({List<Milestone>? milestones}) => Goal(
    id: id,
    title: title,
    createdAt: createdAt,
    why: why,
    category: category,
    deadline: deadline,
    milestones: milestones ?? this.milestones,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'why': why,
    'category': category.name,
    'deadline': deadline?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'milestones': milestones.map((m) => m.toMap()).toList(),
  };

  factory Goal.fromMap(Map m) => Goal(
    id: m['id'],
    title: m['title'],
    why: m['why'] ?? '',
    category: GoalCategory.values.byName(m['category'] ?? 'other'),
    deadline: m['deadline'] == null ? null : DateTime.parse(m['deadline']),
    createdAt: DateTime.parse(m['createdAt']),
    milestones: ((m['milestones'] ?? []) as List)
        .map((e) => Milestone.fromMap(e as Map))
        .toList(),
  );
}

// ---------- الجدول الأسبوعي ----------

enum TaskCategory { classes, study, work, health }

class PlanTask {
  final String id;
  final String title;
  final int weekday;
  final String startTime;
  final String endTime;
  final TaskCategory category;
  final String? goalId;

  const PlanTask({
    required this.id,
    required this.title,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.goalId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'weekday': weekday,
    'startTime': startTime,
    'endTime': endTime,
    'category': category.name,
    'goalId': goalId,
  };

  factory PlanTask.fromMap(Map m) => PlanTask(
    id: m['id'],
    title: m['title'],
    weekday: m['weekday'],
    startTime: m['startTime'],
    endTime: m['endTime'],
    category: TaskCategory.values.byName(m['category']),
    goalId: m['goalId'],
  );
}

class WeeklyGoal {
  final String id;
  final String title;
  final bool done;

  const WeeklyGoal({required this.id, required this.title, this.done = false});

  WeeklyGoal toggled() => WeeklyGoal(id: id, title: title, done: !done);

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'done': done};

  factory WeeklyGoal.fromMap(Map m) =>
      WeeklyGoal(id: m['id'], title: m['title'], done: m['done'] ?? false);
}

class FocusSession {
  final String id;
  final String taskTitle;
  final DateTime startedAt;
  final int minutes;
  final int distractions;

  const FocusSession({
    required this.id,
    required this.taskTitle,
    required this.startedAt,
    required this.minutes,
    this.distractions = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskTitle': taskTitle,
    'startedAt': startedAt.toIso8601String(),
    'minutes': minutes,
    'distractions': distractions,
  };

  factory FocusSession.fromMap(Map m) => FocusSession(
    id: m['id'],
    taskTitle: m['taskTitle'],
    startedAt: DateTime.parse(m['startedAt']),
    minutes: m['minutes'],
    distractions: m['distractions'] ?? 0,
  );
}