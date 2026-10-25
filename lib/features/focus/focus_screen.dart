import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../core/settings.dart';
import 'break_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  static const _durations = [15, 25, 45];
  static const _accent = Color(0xFFB79CF0);
  static const _messages = [
    'مستقبلك هيشكرك على اللي بتعمليه دلوقتي 💜',
    'ركّزي، شوية بس وهتفرحي بنفسك ✨',
    'كل دقيقة تركيز بتقرّبك من هدفك 🎯',
    'الموبايل هيستنى، حلمك أهم 🌸',
  ];

  final _taskC = TextEditingController();
  List<String> _todayTasks = [];
  List<Goal> _goals = [];
  String? _goalId;
  int _minutes = 25;
  int _remaining = 25 * 60; // بالثواني
  bool _running = false;
  DateTime? _endAt;
  DateTime? _startedAt;
  Timer? _timer;
  int _msgIndex = 0;

  int get _total => _minutes * 60;
  bool get _started => _remaining < _total;

  String get _clock {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskC.dispose();
    super.dispose();
  }

  // مهام النهارده من تاب Plan + الأهداف الكبيرة
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> todayTasks = [];
    final tJson = prefs.getString('tasks');
    if (tJson != null) {
      final today = DateTime.now().weekday;
      final tasks = (jsonDecode(tJson) as List)
          .map((e) => PlanTask.fromMap(e as Map))
          .where((t) => t.weekday == today)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      todayTasks = tasks.map((t) => t.title).toList();
    }

    List<Goal> goals = [];
    final gJson = prefs.getString('goals_v2');
    if (gJson != null) {
      goals = (jsonDecode(gJson) as List)
          .map((e) => Goal.fromMap(e as Map))
          .where((g) => g.progress < 100)
          .toList();
    }

    if (!mounted) return;
    final dm = prefs.getInt('default_minutes') ?? 25;
    setState(() {
      _todayTasks = todayTasks;
      _goals = goals;
      _minutes = dm;
      _remaining = dm * 60;
    });
  }

  // تسجيل الجلسة
  Future<void> _saveSession(int minutes) async {
    if (minutes < 1) return;
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('sessions');
    final list = json == null ? <dynamic>[] : jsonDecode(json) as List;
    final title =
    _taskC.text.trim().isEmpty ? 'جلسة تركيز' : _taskC.text.trim();
    list.add(FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskTitle: title,
      startedAt: _startedAt ?? DateTime.now(),
      minutes: minutes,
    ).toMap());
    await prefs.setString('sessions', jsonEncode(list));

    // نجمة لكل 5 دقايق تركيز
    final stars = prefs.getInt('stars') ?? 0;
    await prefs.setInt('stars', stars + minutes ~/ 5);

    // ندوّن الدقايق على الهدف المختار
    if (_goalId != null) {
      final raw = prefs.getString('goal_minutes');
      final map = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
      map[_goalId!] = ((map[_goalId!] ?? 0) as int) + minutes;
      await prefs.setString('goal_minutes', jsonEncode(map));
    }
  }

  // ---------- المؤقت ----------
  void _start() {
    _startedAt ??= DateTime.now();
    _endAt = DateTime.now().add(Duration(seconds: _remaining));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    setState(() => _running = true);
  }

  void _tick() {
    final ms = _endAt!.difference(DateTime.now()).inMilliseconds;
    final r = (ms / 1000).ceil();
    if (r <= 0) {
      _finish();
    } else {
      setState(() => _remaining = r);
    }
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  Future<void> _finish() async {
    _timer?.cancel();
    await _saveSession(_minutes);
    if (!mounted) return;
    final done = _minutes;
    setState(() {
      _running = false;
      _remaining = _total;
      _startedAt = null;
    });
    await showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('برافو! 🎉'),
        content: Text(
            'خلصتي $done دقيقة تركيز (+${done ~/ 5} ⭐). خدي بريك قصير 💜'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(d);
              final bm = AppSettings.instance.breakMin;
              if (bm > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BreakScreen(minutes: bm)),
                );
              }
            },
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  Future<void> _end() async {
    if (!_started) {
      Navigator.pop(context);
      return;
    }
    _pause();
    final elapsed = ((_total - _remaining) / 60).floor();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('تنهي الجلسة؟'),
        content: Text(elapsed >= 1
            ? 'هتتسجل $elapsed دقيقة تركيز 💜'
            : 'لسه ما كملتيش دقيقة، فمش هتتسجل.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('كمّلي')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('إنهاء')),
        ],
      ),
    );
    if (ok == true) {
      await _saveSession(elapsed);
      if (mounted) Navigator.pop(context);
    }
  }

  // ---------- الواجهة ----------
  Widget _goalPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.nightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButton<String?>(
        value: _goals.any((g) => g.id == _goalId) ? _goalId : null,
        isExpanded: true,
        dropdownColor: AppColors.nightCard,
        underline: const SizedBox.shrink(),
        iconEnabledColor: Colors.white70,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        hint: const Text('ربط الجلسة بهدف (اختياري)',
            style: TextStyle(color: Colors.white60)),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('من غير هدف'),
          ),
          for (final g in _goals)
            DropdownMenuItem<String?>(
              value: g.id,
              child: Text(g.title, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged:
        _started ? null : (v) => setState(() => _goalId = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Focus Mode'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _end,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.track_changes, size: 56, color: _accent),
          const SizedBox(height: 8),
          const Text(
            "It's Focus Time!",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'No distractions, just your goals.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),

          // المهمة الحالية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.nightCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _taskC,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'المهمة الحالية',
                labelStyle: TextStyle(color: Colors.white60),
                hintText: 'مثلاً: CCNA Study',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.menu_book, color: _accent),
              ),
            ),
          ),
          if (_todayTasks.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('مهام النهارده (دوسي لو عايزة تختاري منها):',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final t in _todayTasks)
                  ActionChip(
                    label: Text(t),
                    labelStyle: const TextStyle(color: Colors.white),
                    backgroundColor: AppColors.nightCard,
                    onPressed: () => setState(() => _taskC.text = t),
                  ),
              ],
            ),
          ],
          if (_goals.isNotEmpty) ...[
            const SizedBox(height: 12),
            _goalPicker(),
          ],
          const SizedBox(height: 16),

          // اختيار المدة (قبل ما نبدأ بس)
          if (!_started && !_running)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final d in _durations)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('$d د'),
                      selected: _minutes == d,
                      selectedColor: AppColors.purple,
                      backgroundColor: AppColors.nightCard,
                      labelStyle: const TextStyle(color: Colors.white),
                      checkmarkColor: Colors.white,
                      onSelected: (_) => setState(() {
                        _minutes = d;
                        _remaining = d * 60;
                      }),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 20),

          // الدايرة والمؤقت
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: _remaining / _total,
                      strokeWidth: 10,
                      color: _accent,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _clock,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text('Focus Timer',
                          style: TextStyle(color: Colors.white60)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // الأزرار
          FilledButton.icon(
            onPressed: _running ? _pause : _start,
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
            label: Text(_running
                ? 'Pause'
                : (_started ? 'Resume' : 'Start Focus')),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _end,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('End Focus'),
          ),
          const SizedBox(height: 20),

          // رسالة تحفيزية (دوسي عليها تتغير)
          InkWell(
            onTap: () => setState(
                    () => _msgIndex = (_msgIndex + 1) % _messages.length),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.nightCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF2B84B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Quotes.focusAt(_msgIndex),
                      style: const TextStyle(
                          color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}