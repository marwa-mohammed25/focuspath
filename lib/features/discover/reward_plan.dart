import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class _Level {
  final int from;
  final String name;
  const _Level(this.from, this.name);
}

class RewardPlan extends StatefulWidget {
  final List<String> steps;
  const RewardPlan({super.key, required this.steps});

  @override
  State<RewardPlan> createState() => _RewardPlanState();
}

class _RewardPlanState extends State<RewardPlan> {
  static const _stepStars = 10;
  static const _bonusStars = 30;
  static const _levels = [
    _Level(0, 'بذرة 🌱'),
    _Level(30, 'برعم 🌷'),
    _Level(80, 'زهرة 🌸'),
    _Level(150, 'نجمة ✨'),
  ];
  static const _gold = AppColors.purple;

  Set<int> _done = {};
  int _stars = 0;
  String _reward = '';
  bool _loading = true;

  // بصمة الخطة: لو الخطة اتغيرت (بعد إعادة الأسئلة) التقدم بيبدأ من الأول
  String get _sig => widget.steps.join('|');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final sameSig = prefs.getString('plan_sig') == _sig;
    Set<int> done = {};
    if (sameSig) {
      done = (prefs.getStringList('plan_done') ?? []).map(int.parse).toSet();
    } else {
      await prefs.setString('plan_sig', _sig);
      await prefs.setStringList('plan_done', <String>[]);
    }
    if (!mounted) return;
    setState(() {
      _done = done;
      _stars = prefs.getInt('stars') ?? 0;
      _reward = prefs.getString('plan_reward') ?? '';
      _loading = false;
    });
  }

  int _levelIndex(int s) {
    int idx = 0;
    for (int i = 0; i < _levels.length; i++) {
      if (s >= _levels[i].from) idx = i;
    }
    return idx;
  }

  Future<void> _complete(int i) async {
    if (_done.contains(i)) return;
    final newDone = {..._done, i};
    final all = newDone.length == widget.steps.length;
    final gained = _stepStars + (all ? _bonusStars : 0);
    final oldIdx = _levelIndex(_stars);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'plan_done', newDone.map((e) => '$e').toList());
    await prefs.setInt('stars', _stars + gained);
    if (!mounted) return;

    setState(() {
      _done = newDone;
      _stars += gained;
    });

    final newIdx = _levelIndex(_stars);
    final levelUp = newIdx > oldIdx;

    if (all) {
      await showDialog(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('برافو! خلصتي خطتك 🎉',
              textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 60, color: _gold),
              const SizedBox(height: 10),
              Text('+$gained نجمة (منهم $_bonusStars بونص)',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (levelUp) ...[
                const SizedBox(height: 8),
                Text('ووصلتي لمستوى ${_levels[newIdx].name}',
                    style: const TextStyle(color: AppColors.purple)),
              ],
              const SizedBox(height: 14),
              Text(
                _reward.isEmpty
                    ? 'خدي مكافأة صغيرة بتحبيها، إنتي تستاهلي 💜'
                    : 'مكافأتك: $_reward 🎁\nاستحقيتيها!',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.6),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d),
                child: const Text('تمام')),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(levelUp
              ? '+$_stepStars ⭐ ووصلتي لمستوى ${_levels[newIdx].name} 🎉'
              : '+$_stepStars ⭐ برافو، كمّلي! 💜'),
        ),
      );
    }
  }

  Future<void> _editReward() async {
    final c = TextEditingController(text: _reward);
    final r = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('مكافأتك لنفسك 🎁'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'مثلاً: فنجان قهوة، فيلم، خروجة'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(d, c.text.trim()),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (r == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('plan_reward', r);
    if (!mounted) return;
    setState(() => _reward = r);
  }

  Widget _starsBox() {
    final idx = _levelIndex(_stars);
    final cur = _levels[idx];
    final isTop = idx == _levels.length - 1;
    final next = isTop ? cur.from : _levels[idx + 1].from;
    final double progress =
    isTop ? 1.0 : (_stars - cur.from) / (next - cur.from);

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purpleLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: _gold),
              const SizedBox(width: 8),
              Text('$_stars نجمة',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
              const Spacer(),
              Text('مستواك: ${cur.name}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 7,
              color: _gold,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isTop
                ? 'وصلتي لأعلى مستوى، إنتي نجمة! ✨'
                : 'باقي ${next - _stars} نجمة للمستوى الجاي',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final total = widget.steps.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: AppColors.purple),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('خطتك الصغيرة ومكافآتك 🎁',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink)),
              ),
              Text('${_done.length}/$total',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.purple)),
            ],
          ),
          _starsBox(),
          const SizedBox(height: 4),
          for (int i = 0; i < total; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: _done.contains(i) ? null : () => _complete(i),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _done.contains(i)
                        ? const Color(0xFFE3F5EC)
                        : AppColors.blush,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _done.contains(i)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _done.contains(i)
                            ? const Color(0xFF2E9E6B)
                            : Colors.black38,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.steps[i],
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppColors.ink,
                            decoration: _done.contains(i)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (!_done.contains(i))
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.purpleLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('+10 ⭐',
                              style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const Text(
            'دوسي على الخطوة لما تخلصيها وهتاخدي نجومك. وإنهاء الخطة كلها بيدّيكي 30 نجمة بونص 🎉',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.6),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _editReward,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: AppColors.purple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مكافأتي لما أخلص الخطة',
                            style: TextStyle(
                                fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 2),
                        Text(
                          _reward.isEmpty
                              ? 'دوسي واكتبي مكافأة بتحبيها 💜'
                              : _reward,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _reward.isEmpty
                                ? Colors.black45
                                : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, size: 18, color: AppColors.purple),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}