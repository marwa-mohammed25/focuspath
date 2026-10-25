import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../core/settings.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _pink = Color(0xFFE8739A);

  static const _quotes = [
    'كل خطوة صغيرة النهاردة بتقرّبك من حلمك 💜',
    'إنتي أقوى مما تتخيلي، كمّلي!',
    'التركيز دلوقتي هو شكرك لنفسك بكرة ✨',
    'مش لازم تكوني مثالية، لازم بس تبدئي 🌱',
    'اللي بتتعبي عليه النهاردة هتفرحي بيه قريب 🌸',
    'يوم واحد مركّز أحسن من أسبوع مشتت 🎯',
  ];

  int _quoteIndex = DateTime.now().day % _quotes.length;
  int _selectedWeekday = DateTime.now().weekday;

  final List<PlanTask> _tasks = [];
  List<WeeklyGoal> _goals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------- التخزين ----------
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('tasks');
    final goalsJson = prefs.getString('goals');
    if (!mounted) return;
    setState(() {
      if (tasksJson != null) {
        _tasks
          ..clear()
          ..addAll((jsonDecode(tasksJson) as List)
              .map((e) => PlanTask.fromMap(e as Map)));
      }
      if (goalsJson != null) {
        _goals = (jsonDecode(goalsJson) as List)
            .map((e) => WeeklyGoal.fromMap(e as Map))
            .toList();
      }
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'tasks', jsonEncode(_tasks.map((t) => t.toMap()).toList()));
    await prefs.setString(
        'goals', jsonEncode(_goals.map((g) => g.toMap()).toList()));
  }

  // ---------- الأهداف ----------
  void _toggleGoal(int index) {
    setState(() {
      _goals = [
        for (int i = 0; i < _goals.length; i++)
          if (i == index) _goals[i].toggled() else _goals[i],
      ];
    });
    _save();
  }

  void _deleteGoal(int index) {
    setState(() {
      _goals = [
        for (int i = 0; i < _goals.length; i++)
          if (i != index) _goals[i],
      ];
    });
    _save();
  }

  Future<void> _addGoal() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('هدف جديد للأسبوع'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      setState(() {
        _goals = [
          ..._goals,
          WeeklyGoal(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title),
        ];
      });
      _save();
    }
  }

  // ---------- المهام ----------
  String _toHHmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmt(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${parts[1]} $period';
  }

  Future<void> _addTask() async {
    final titleController = TextEditingController();
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 10, minute: 0);
    TaskCategory category = TaskCategory.study;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('مهمة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'اسم المهمة'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final p = await showTimePicker(
                            context: ctx, initialTime: start);
                        if (p != null) setLocal(() => start = p);
                      },
                      child: Text('من ${_fmt(_toHHmm(start))}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final p = await showTimePicker(
                            context: ctx, initialTime: end);
                        if (p != null) setLocal(() => end = p);
                      },
                      child: Text('إلى ${_fmt(_toHHmm(end))}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButton<TaskCategory>(
                value: category,
                isExpanded: true,
                items: [
                  for (final c in TaskCategory.values)
                    DropdownMenuItem(value: c, child: Text(_categoryLabel(c))),
                ],
                onChanged: (v) => setLocal(() => category = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    final title = titleController.text.trim();
    if (ok == true && title.isNotEmpty) {
      setState(() {
        _tasks.add(PlanTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          weekday: _selectedWeekday,
          startTime: _toHHmm(start),
          endTime: _toHHmm(end),
          category: category,
        ));
      });
      _save();
    }
  }

  // ---------- الألوان والأيقونات ----------
  Color _catColor(TaskCategory c) {
    switch (c) {
      case TaskCategory.classes:
        return const Color(0xFF9B7BDB);
      case TaskCategory.study:
        return const Color(0xFF2EB67D);
      case TaskCategory.work:
        return const Color(0xFF4A90E2);
      case TaskCategory.health:
        return _pink;
    }
  }

  IconData _catIcon(TaskCategory c) {
    switch (c) {
      case TaskCategory.classes:
        return Icons.school;
      case TaskCategory.study:
        return Icons.menu_book;
      case TaskCategory.work:
        return Icons.laptop_mac;
      case TaskCategory.health:
        return Icons.fitness_center;
    }
  }

  String _categoryLabel(TaskCategory c) {
    switch (c) {
      case TaskCategory.classes:
        return 'Class';
      case TaskCategory.study:
        return 'Study';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.health:
        return 'Health';
    }
  }

  // ---------- العناصر ----------
  Widget _hero(int todayCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B5EA7), Color(0xFFB07CC6), Color(0xFFE8739A)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Weekly Plan 📅',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  todayCount == 0
                      ? 'اليوم ده فاضي، ضيفي أول مهمة'
                      : '$todayCount مهام في اليوم ده 💪',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _addTask,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.purple, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteCard() {
    return InkWell(
      onTap: () =>
          setState(() => _quoteIndex = (_quoteIndex + 1) % _quotes.length),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE3EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.format_quote_rounded, color: _pink, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                Quotes.at(_quoteIndex),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayTile(DateTime d) {
    final selected = d.weekday == _selectedWeekday;
    final hasTasks = _tasks.any((t) => t.weekday == d.weekday);

    return GestureDetector(
      onTap: () => setState(() => _selectedWeekday = d.weekday),
      child: Container(
        width: 56,
        decoration: BoxDecoration(
          color: selected ? null : Colors.white,
          gradient: selected
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7B5EA7), Color(0xFFE8739A)],
          )
              : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (selected ? AppColors.purple : Colors.black)
                  .withOpacity(selected ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _dayNames[d.weekday - 1],
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${d.day}',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasTasks
                    ? (selected ? Colors.white : _pink)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskCard(PlanTask t) {
    final color = _catColor(t.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(_catIcon(t.category), color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_fmt(t.startTime)} - ${_fmt(t.endTime)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _categoryLabel(t.category),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() => _tasks.removeWhere((x) => x.id == t.id));
                _save();
              },
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalsCard() {
    final doneCount = _goals.where((g) => g.done).length;
    final progress = _goals.isEmpty ? 0.0 : doneCount / _goals.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Weekly Goals 🎯',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$doneCount/${_goals.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: _pink,
              backgroundColor: AppColors.purpleLight,
            ),
          ),
          const SizedBox(height: 8),
          if (_goals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('مفيش أهداف لسه، دوسي "إضافة هدف" وابدأي بهدفك الأول'),
            ),
          for (int i = 0; i < _goals.length; i++)
            CheckboxListTile(
              value: _goals[i].done,
              onChanged: (_) => _toggleGoal(i),
              title: Text(
                _goals[i].title,
                style: TextStyle(
                  color: AppColors.ink,
                  decoration:
                  _goals[i].done ? TextDecoration.lineThrough : null,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: _pink,
              secondary: IconButton(
                onPressed: () => _deleteGoal(i),
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.black38),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addGoal,
              icon: const Icon(Icons.add),
              label: const Text('إضافة هدف'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){
  final today = DateTime.now();
  final ws = AppSettings.instance.weekStart;
  final back = (today.weekday - ws + 7) % 7;
  final start = DateTime(today.year, today.month, today.day - back);
  final days = List.generate(
  7, (i) => DateTime(start.year, start.month, start.day + i));
    final dayTasks = _tasks.where((t) => t.weekday == _selectedWeekday).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _hero(dayTasks.length),
        const SizedBox(height: 14),
        _quoteCard(),
        const SizedBox(height: 16),

        // اختيار اليوم
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _dayTile(days[i]),
          ),
        ),
        const SizedBox(height: 18),

        // مهام اليوم
        if (dayTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.event_available,
                    size: 34, color: AppColors.purple),
                SizedBox(height: 8),
                Text('مفيش مهام في اليوم ده، دوسي + عشان تضيفي',
                    style: TextStyle(color: AppColors.ink)),
              ],
            ),
          )
        else
          for (final t in dayTasks) _taskCard(t),
        const SizedBox(height: 14),

        _goalsCard(),
        const SizedBox(height: 10),
      ],
    );
  }
}