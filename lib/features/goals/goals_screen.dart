import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import 'vision_board.dart';
import 'goal_time.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _Status {
  final String text;
  final Color color;
  const _Status(this.text, this.color);
}

class _GoalsScreenState extends State<GoalsScreen> {
  static const _green = Color(0xFF2E9E6B);
  static const _orange = Color(0xFFE08A1E);
  static const _red = Color(0xFFD64545);

  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------- التخزين ----------
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('goals_v2');
    if (json == null || !mounted) return;
    setState(() {
      _goals = (jsonDecode(json) as List)
          .map((e) => Goal.fromMap(e as Map))
          .toList();
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'goals_v2', jsonEncode(_goals.map((g) => g.toMap()).toList()));
  }

  // ---------- مساعدات ----------
  String _catLabel(GoalCategory c) {
    switch (c) {
      case GoalCategory.study:
        return 'دراسة';
      case GoalCategory.work:
        return 'شغل';
      case GoalCategory.health:
        return 'صحة';
      case GoalCategory.language:
        return 'لغة';
      case GoalCategory.other:
        return 'أخرى';
    }
  }

  IconData _catIcon(GoalCategory c) {
    switch (c) {
      case GoalCategory.study:
        return Icons.menu_book;
      case GoalCategory.work:
        return Icons.work_outline;
      case GoalCategory.health:
        return Icons.fitness_center;
      case GoalCategory.language:
        return Icons.language;
      case GoalCategory.other:
        return Icons.star_outline;
    }
  }

  List<Color> _grad(GoalCategory c) {
    switch (c) {
      case GoalCategory.study:
        return const [Color(0xFF6FD6B5), Color(0xFF2EB67D)];
      case GoalCategory.work:
        return const [Color(0xFF7FB2FF), Color(0xFF4A90E2)];
      case GoalCategory.health:
        return const [Color(0xFFFF9AA2), Color(0xFFE8739A)];
      case GoalCategory.language:
        return const [Color(0xFFB79CF0), Color(0xFF7B5EA7)];
      case GoalCategory.other:
        return const [Color(0xFFFFC27A), Color(0xFFF59E3D)];
    }
  }

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _dateText(DateTime d) => '${d.day}/${d.month}/${d.year}';

  int? _daysLeft(Goal g) {
    if (g.deadline == null) return null;
    return g.deadline!.difference(_today()).inDays;
  }

  _Status? _status(Goal g) {
    if (g.progress >= 100) return const _Status('تم الإنجاز 🎉', _green);
    final d = g.deadline;
    if (d == null) return null;
    final today = _today();
    if (d.difference(today).inDays < 0) {
      return const _Status('فات الموعد', _red);
    }
    final created =
    DateTime(g.createdAt.year, g.createdAt.month, g.createdAt.day);
    final total = d.difference(created).inDays;
    final elapsed = today.difference(created).inDays;
    final expected =
    total <= 0 ? 100.0 : (elapsed / total * 100).clamp(0, 100).toDouble();
    if (g.progress >= expected - 10) {
      return const _Status('على المسار ✅', _green);
    }
    return const _Status('محتاج تسريع ⚠️', _orange);
  }

  int _avg() {
    if (_goals.isEmpty) return 0;
    final sum = _goals.fold<int>(0, (s, g) => s + g.progress);
    return (sum / _goals.length).round();
  }

  String _message(int avg) {
    if (_goals.isEmpty) return 'ابدأي بأول حلم ليكي 💜';
    if (avg >= 100) return 'خلصتي كل أهدافك! إنتي بطلة 🏆';
    if (avg >= 70) return 'قربتي جداً! كمّلي 🔥';
    if (avg >= 30) return 'ماشية صح، استمري 💪';
    return 'البداية دايماً أصعب جزء، كمّلي 💜';
  }

  void _replace(Goal g) {
    setState(() {
      _goals = [
        for (final x in _goals)
          if (x.id == g.id) g else x,
      ];
    });
    _save();
  }

  void _deleteGoal(String id) {
    setState(() => _goals = _goals.where((g) => g.id != id).toList());
    _save();
  }

  Future<String?> _askText(BuildContext ctx, String title,
      {String hint = ''}) {
    final c = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(d, c.text.trim()),
              child: const Text('إضافة')),
        ],
      ),
    );
  }

  Future<bool?> _confirm(BuildContext ctx, String msg) {
    return showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('لأ')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('أيوه، امسحيه')),
        ],
      ),
    );
  }

  // ---------- إضافة هدف ----------
  Future<void> _addGoal() async {
    final titleC = TextEditingController();
    final whyC = TextEditingController();
    GoalCategory cat = GoalCategory.study;
    DateTime? deadline;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('هدف جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'إيه هدفك؟'),
                ),
                TextField(
                  controller: whyC,
                  decoration: const InputDecoration(
                      labelText: 'ليه بدأتي؟ (اختياري)'),
                ),
                const SizedBox(height: 12),
                DropdownButton<GoalCategory>(
                  value: cat,
                  isExpanded: true,
                  items: [
                    for (final c in GoalCategory.values)
                      DropdownMenuItem(value: c, child: Text(_catLabel(c))),
                  ],
                  onChanged: (v) => setLocal(() => cat = v!),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: _today().add(const Duration(days: 30)),
                      firstDate: _today(),
                      lastDate: _today().add(const Duration(days: 3650)),
                    );
                    if (p != null) setLocal(() => deadline = p);
                  },
                  icon: const Icon(Icons.event),
                  label: Text(deadline == null
                      ? 'حددي موعد (اختياري)'
                      : _dateText(deadline!)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('إضافة')),
          ],
        ),
      ),
    );

    final title = titleC.text.trim();
    if (ok == true && title.isNotEmpty) {
      setState(() {
        _goals = [
          ..._goals,
          Goal(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            why: whyC.text.trim(),
            category: cat,
            deadline: deadline,
            createdAt: DateTime.now(),
          ),
        ];
      });
      _save();
    }
  }

  // ---------- تفاصيل الهدف والخطوات ----------
  void _toggleMilestone(Goal g, String mid) {
    final before = g.progress;
    final updated = g.copyWith(milestones: [
      for (final m in g.milestones)
        if (m.id == mid) m.toggled() else m,
    ]);
    _replace(updated);
    if (before < 100 && updated.progress >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبروك! خلصتي الهدف 🎉💜')),
      );
    }
  }

  void _openGoal(String id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final i = _goals.indexWhere((x) => x.id == id);
          if (i == -1) return const SizedBox.shrink();
          final g = _goals[i];
          final grad = _grad(g.category);
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: grad),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_catIcon(g.category), color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          g.title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final ok = await _confirm(ctx, 'تمسحي الهدف ده؟');
                          if (ok == true) {
                            Navigator.pop(ctx);
                            _deleteGoal(id);
                          }
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (g.why.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '"${g.why}"',
                        style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.purple),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: g.progress / 100,
                            minHeight: 10,
                            color: grad.last,
                            backgroundColor: grad.last.withOpacity(0.15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${g.progress}%',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: grad.last)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('الخطوات',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink)),
                  if (g.milestones.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                          'قسّمي هدفك لخطوات صغيرة، وكل خطوة تخلصيها النسبة هتزيد لوحدها 💜'),
                    ),
                  for (final m in g.milestones)
                    CheckboxListTile(
                      value: m.done,
                      onChanged: (_) {
                        _toggleMilestone(g, m.id);
                        setLocal(() {});
                      },
                      title: Text(
                        m.title,
                        style: TextStyle(
                          color: AppColors.ink,
                          decoration:
                          m.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: grad.last,
                      secondary: IconButton(
                        onPressed: () {
                          _replace(g.copyWith(milestones: [
                            for (final x in g.milestones)
                              if (x.id != m.id) x,
                          ]));
                          setLocal(() {});
                        },
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.black45),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final t = await _askText(ctx, 'خطوة جديدة',
                          hint: 'مثلاً: Chapter 1');
                      if (t != null && t.isNotEmpty) {
                        _replace(g.copyWith(milestones: [
                          ...g.milestones,
                          Milestone(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            title: t,
                          ),
                        ]));
                        setLocal(() {});
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة خطوة'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- الواجهة ----------
  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _hero() {
    final avg = _avg();
    final done = _goals.where((g) => g.progress >= 100).length;
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
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: avg / 100,
                    strokeWidth: 9,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
                Text('$avg%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_message(avg),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('${_goals.length} أهداف، $done تحققت',
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(Goal g) {
    final status = _status(g);
    final left = _daysLeft(g);
    final total = g.milestones.length;
    final doneCount = g.milestones.where((m) => m.done).length;
    final grad = _grad(g.category);

    String leftText = '';
    if (left != null) {
      if (left == 0) {
        leftText = 'آخر يوم النهاردة';
      } else if (left > 0) {
        leftText = 'باقي $left يوم';
      } else {
        leftText = 'عدّى ${-left} يوم';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => _openGoal(g.id),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: grad.last.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: grad,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_catIcon(g.category), color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      g.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink),
                    ),
                  ),
                  Text('${g.progress}%',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: grad.last)),
                ],
              ),
              if (g.why.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '"${g.why}"',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: g.progress / 100,
                  minHeight: 9,
                  color: grad.last,
                  backgroundColor: grad.last.withOpacity(0.15),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (status != null) _chip(status.text, status.color),
                  if (left != null && g.progress < 100)
                    Text(leftText,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  Text(
                    total == 0
                        ? 'دوسي وضيفي خطوات'
                        : '$doneCount/$total خطوات',
                    style:
                    const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  GoalTime(goalId: g.id),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'My Goals 🎯',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink),
              ),
            ),
            GestureDetector(
              onTap: _addGoal,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B5EA7), Color(0xFFE8739A)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _hero(),
        const SizedBox(height: 22),
        const VisionBoard(),
        const SizedBox(height: 22),
        if (_goals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.flag, size: 34, color: AppColors.purple),
                SizedBox(height: 8),
                Text('لسه مفيش أهداف، دوسي + وابدأي بحلمك الأول',
                    style: TextStyle(color: AppColors.ink)),
              ],
            ),
          )
        else ...[
          const Text(
            'أهدافي',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          for (final g in _goals) _goalCard(g),
        ],
      ],
    );
  }
}