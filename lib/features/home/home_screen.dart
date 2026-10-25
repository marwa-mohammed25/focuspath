import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../focus/focus_screen.dart';
import '../../core/theme_filter.dart';
import 'rewards_card.dart';
import 'mood_card.dart';
import '../../core/settings.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  /// بتفتح تاب معين: 2 = Plan ، 3 = Profile (الأهداف)
  final void Function(int tabIndex) onGoToTab;

  const HomeScreen({super.key, required this.onGoToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _target = 60; // هدف التركيز اليومي بالدقايق
  static const _pink = Color(0xFFE8739A);
  static const _orange = Color(0xFFF59E3D);
  static const _green = Color(0xFF2EB67D);

  static const _quotes = [
    'Big dreams need less scrolling and more focus! ✨',
    'مستقبلك هيشكرك على اللي بتعمليه دلوقتي 💜',
    'Small steps every day lead to big results 🌱',
    'إنتي أقوى مما تتخيلي، كمّلي! 🔥',
    'Focus on progress, not perfection 🌸',
  ];

  String _name = '';
  String _quote = '';
  int _focusMinutes = 0;
  int _sessions = 0;
  int _weeklyDone = 0;
  int _weeklyTotal = 0;
  int _goalsAvg = 0;
  int _goalsCount = 0;
  int _quoteIdx = DateTime.now().day % _quotes.length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // جلسات التركيز بتاعة النهارده
    int mins = 0;
    int sessions = 0;
    final sJson = prefs.getString('sessions');
    if (sJson != null) {
      for (final e in jsonDecode(sJson) as List) {
        final s = FocusSession.fromMap(e as Map);
        final d = s.startedAt;
        if (d.year == now.year && d.month == now.month && d.day == now.day) {
          mins += s.minutes;
          sessions++;
        }
      }
    }

    // أهداف الأسبوع
    int done = 0;
    int total = 0;
    final wJson = prefs.getString('goals');
    if (wJson != null) {
      final list = (jsonDecode(wJson) as List)
          .map((e) => WeeklyGoal.fromMap(e as Map))
          .toList();
      total = list.length;
      done = list.where((g) => g.done).length;
    }

    // الأهداف الكبيرة
    int avg = 0;
    int count = 0;
    final gJson = prefs.getString('goals_v2');
    if (gJson != null) {
      final list = (jsonDecode(gJson) as List)
          .map((e) => Goal.fromMap(e as Map))
          .toList();
      count = list.length;
      if (count > 0) {
        avg = (list.fold<int>(0, (s, g) => s + g.progress) / count).round();
      }
    }

    if (!mounted) return;
    setState(() {
      _target = prefs.getInt('daily_target') ?? 60;
      _name = prefs.getString('user_name') ?? '';
      _quote = prefs.getString('personal_quote') ?? '';
      _focusMinutes = mins;
      _sessions = sessions;
      _weeklyDone = done;
      _weeklyTotal = total;
      _goalsAvg = avg;
      _goalsCount = count;
    });
  }

  Future<void> _saveText(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> _askText(String title, String current, {int lines = 1}) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: lines,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _editName() async {
    final r = await _askText('اسمك', _name);
    if (r != null) {
      setState(() => _name = r);
      _saveText('user_name', r);
    }
  }

  Future<void> _editQuote() async {
    final r = await _askText('جملتك الشخصية', _quote, lines: 2);
    if (r != null) {
      setState(() => _quote = r);
      _saveText('personal_quote', r);
    }
  }

  Future<void> _openFocus() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UndoDark(child: FocusScreen())),
    );
    _load(); // نحدّث الأرقام بعد ما نرجع من جلسة التركيز
  }
  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    _load();
  }

  void _soon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('الشاشة دي قريباً 💜')),
    );
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _greetEmoji {
    final h = DateTime.now().hour;
    if (h < 12) return '☀️';
    if (h < 18) return '🌤️';
    return '🌙';
  }

  String _fmtMins(int m) {
    final h = m ~/ 60;
    final r = m % 60;
    return h == 0 ? '${r}m' : '${h}h ${r}m';
  }

  // ---------- العناصر ----------
  Widget _title(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.ink,
    ),
  );

  Widget _hero() {
    final progress = (_focusMinutes / _target).clamp(0.0, 1.0);
    final left = _target - _focusMinutes;

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
            child: InkWell(
              onTap: _editName,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting $_greetEmoji',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _name.isEmpty ? 'اكتبي اسمك هنا ✏️' : '$_name! 💜',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _name.isEmpty ? 18 : 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    left <= 0
                        ? 'حققتي هدف تركيز النهارده! 🎉'
                        : 'باقي $left دقيقة لهدف تركيز النهارده',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_focusMinutes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'min',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyQuote() {
    return GestureDetector(
      onTap: () => setState(() => _quoteIdx = (_quoteIdx + 1) % _quotes.length),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE3EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.format_quote_rounded, color: _pink, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                Quotes.at(_quoteIdx),
                style: const TextStyle(
                  fontSize: 16,
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

  Widget _personalQuote() {
    return InkWell(
      onTap: _editQuote,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.purpleLight, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: _pink, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'جملتي لنفسي',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _quote.isEmpty
                        ? 'دوسي هنا واكتبي جملتك الشخصية 💜'
                        : _quote,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _quote.isEmpty ? Colors.black38 : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 18, color: AppColors.purple),
          ],
        ),
      ),
    );
  }

  Widget _cta() {
    return GestureDetector(
      onTap: _openFocus,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B8DEF), Color(0xFF7B5EA7)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B8DEF).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'ابدئي جلسة تركيز',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _hero(),
        const SizedBox(height: 16),
        _dailyQuote(),
        const SizedBox(height: 12),
        _personalQuote(),
        const SizedBox(height: 16),
        _cta(),
        const SizedBox(height: 16),
        MoodCard(sessions: _sessions),
        const SizedBox(height: 24),

        _title("Today's Overview ✨"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.timer,
                color: AppColors.purple,
                value: _fmtMins(_focusMinutes),
                label: 'Focus Time',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.bolt,
                color: _orange,
                value: '$_sessions',
                label: 'Sessions',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.checklist,
                color: _green,
                value: _weeklyTotal == 0 ? '-' : '$_weeklyDone / $_weeklyTotal',
                label: 'Weekly Goals',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events,
                color: _pink,
                value: _goalsCount == 0 ? '-' : '$_goalsAvg%',
                label: 'Big Goals',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (!AppSettings.instance.calm) ...[
          RewardsCard(sessions: _sessions),
          const SizedBox(height: 24),
        ],

        _title('Quick Actions ⚡'),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ActionTile(
              icon: Icons.track_changes,
              label: 'My Goals',
              colors: const [Color(0xFFFF9AA2), Color(0xFFE8739A)],
              onTap: () => widget.onGoToTab(3),
            ),
            _ActionTile(
              icon: Icons.calendar_month,
              label: 'Weekly Plan',
              colors: const [Color(0xFF7FB2FF), Color(0xFF4A90E2)],
              onTap: () => widget.onGoToTab(2),
            ),
            _ActionTile(
              icon: Icons.bolt,
              label: 'Focus Mode',
              colors: const [Color(0xFFB79CF0), Color(0xFF7B5EA7)],
              onTap: _openFocus,
            ),
            _ActionTile(
              icon: Icons.settings,
              label: 'Settings',
              colors: const [Color(0xFF6FD6B5), Color(0xFF2EB67D)],
              onTap: _openSettings,
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}