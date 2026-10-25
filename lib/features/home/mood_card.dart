import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../data/models.dart';

class MoodCard extends StatefulWidget {
  final int sessions;
  const MoodCard({super.key, this.sessions = 0});

  @override
  State<MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends State<MoodCard> {
  static const _emojis = ['😊', '🙂', '😐', '😔'];
  static const _labels = ['مبسوطة', 'كويسة', 'عادي', 'تعبانة'];
  static const _colors = [
    Color(0xFF2EB67D),
    Color(0xFF4A90E2),
    Color(0xFFF59E3D),
    Color(0xFFE8739A),
  ];
  static const _msgs = [
    'حلو قوي! استغلي طاقتك دي في جلسة تركيز 🔥',
    'جميل، كمّلي يومك بهدوء 🌿',
    'عادي، وده طبيعي. ابدئي بحاجة صغيرة 💜',
    'يوم تقيل؟ مش لازم تكوني مثالية النهارده. خدي نفس عميق وعملي حاجة صغيرة بس 🌸',
  ];
  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Map<String, int> _moods = {};
  Map<String, int> _focus = {};
  bool _loading = true;

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // لما عدد الجلسات يتغير نحدّث المقارنة
  @override
  void didUpdateWidget(covariant MoodCard old) {
    super.didUpdateWidget(old);
    if (old.sessions != widget.sessions) _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final moods = <String, int>{};
    final mJson = prefs.getString('moods');
    if (mJson != null) {
      (jsonDecode(mJson) as Map).forEach((k, v) {
        moods[k as String] = v as int;
      });
    }

    // دقايق التركيز لكل يوم
    final focus = <String, int>{};
    final sJson = prefs.getString('sessions');
    if (sJson != null) {
      for (final e in jsonDecode(sJson) as List) {
        final s = FocusSession.fromMap(e as Map);
        final k = _key(s.startedAt);
        focus[k] = (focus[k] ?? 0) + s.minutes;
      }
    }

    if (!mounted) return;
    setState(() {
      _moods = moods;
      _focus = focus;
      _loading = false;
    });
  }

  Future<void> _pick(int i) async {
    final k = _key(DateTime.now());
    setState(() => _moods = {..._moods, k: i});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('moods', jsonEncode(_moods));
  }

  int _avg(List<int> l) =>
      (l.fold<int>(0, (s, x) => s + x) / l.length).round();

  String _insight() {
    final good = <int>[];
    final hard = <int>[];
    _moods.forEach((k, m) {
      final mins = _focus[k] ?? 0;
      if (m <= 1) {
        good.add(mins);
      } else {
        hard.add(mins);
      }
    });

    if (_moods.length < 3 || good.isEmpty || hard.isEmpty) {
      return 'سجّلي مزاجك كل يوم، وبعد كام يوم هنوريكي إزاي مزاجك بيأثر على تركيزك 💜';
    }

    final g = _avg(good);
    final h = _avg(hard);
    final base =
        'في أيامك المرتاحة بتركزي حوالي $g دقيقة، وفي الأيام التقيلة حوالي $h دقيقة.';
    if (g > h) {
      return '$base\nيعني راحتك بتساعدك تركزي، خدي بالك من نفسك 💜';
    }
    return '$base\nحتى في الأيام التقيلة بتكمّلي، إنتي أقوى مما تتخيلي 💪';
  }

  Widget _moodButton(int i, int? today) {
    final selected = today == i;
    final color = _colors[i];

    return GestureDetector(
      onTap: () => _pick(i),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: selected ? color : color.withOpacity(0.12),
              shape: BoxShape.circle,
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              _emojis[i],
              style: TextStyle(fontSize: selected ? 32 : 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _labels[i],
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? color : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekStrip() {
    final now = DateTime.now();
    final days = List.generate(
      7,
          (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final d in days)
          Column(
            children: [
              Text(
                _moods.containsKey(_key(d)) ? _emojis[_moods[_key(d)]!] : '·',
                style: TextStyle(
                  fontSize: _moods.containsKey(_key(d)) ? 22 : 18,
                  color: Colors.black26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _names[d.weekday - 1],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: _key(d) == _key(now)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _key(d) == _key(now)
                      ? AppColors.purple
                      : Colors.black54,
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 180);

    final today = _moods[_key(DateTime.now())];

    return Container(
      padding: const EdgeInsets.all(18),
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
          const Text(
            'إحساسك النهارده إيه؟ 🌈',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < 4; i++) _moodButton(i, today),
            ],
          ),
          if (today != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _colors[today].withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _msgs[today],
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _weekStrip(),
          const SizedBox(height: 14),
          Text(
            _insight(),
            style: const TextStyle(
              fontSize: 13,
              height: 1.7,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}