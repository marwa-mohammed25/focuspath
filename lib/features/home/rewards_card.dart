import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../data/models.dart';

class RewardsCard extends StatefulWidget {
  final int sessions;
  const RewardsCard({super.key, this.sessions = 0});

  @override
  State<RewardsCard> createState() => _RewardsCardState();
}

class _RewardsCardState extends State<RewardsCard> {
  static const _from = [0, 30, 80, 150];
  static const _names = ['بذرة 🌱', 'برعم 🌷', 'زهرة 🌸', 'نجمة ✨'];
  static const _gold = AppColors.purple;

  int _stars = 0;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // لما عدد الجلسات يتغير (بعد ما نرجع من Focus Mode) نحدّث الكارت
  @override
  void didUpdateWidget(covariant RewardsCard old) {
    super.didUpdateWidget(old);
    if (old.sessions != widget.sessions) _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // الأيام اللي فيها جلسة تركيز
    final days = <DateTime>{};
    final json = prefs.getString('sessions');
    if (json != null) {
      for (final e in jsonDecode(json) as List) {
        final d = FocusSession.fromMap(e as Map).startedAt;
        days.add(DateTime(d.year, d.month, d.day));
      }
    }

    // السلسلة: بنعدّ الأيام المتتالية لورا (من النهارده أو من إمبارح)
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if (!days.contains(day)) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    int streak = 0;
    while (days.contains(day)) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }

    if (!mounted) return;
    setState(() {
      _stars = prefs.getInt('stars') ?? 0;
      _streak = streak;
      _loading = false;
    });
  }

  int get _idx {
    int i = 0;
    for (int k = 0; k < _from.length; k++) {
      if (_stars >= _from[k]) i = k;
    }
    return i;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 130);

    final idx = _idx;
    final isTop = idx == _from.length - 1;
    final double progress =
    isTop ? 1.0 : (_stars - _from[idx]) / (_from[idx + 1] - _from[idx]);
    final toNext = isTop ? 0 : _from[idx + 1] - _stars;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purpleLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: _gold),
              const SizedBox(width: 8),
              Text(
                '$_stars نجمة',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                _names[idx],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              color: _gold,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isTop
                ? 'وصلتي لأعلى مستوى، إنتي نجمة! ✨'
                : 'باقي $toNext نجمة للمستوى الجاي: ${_names[idx + 1]}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _streak == 0
                      ? 'ابدئي جلسة تركيز النهارده وابدئي سلسلتك'
                      : '$_streak يوم تركيز متتالي، كمّلي ومتكسريش السلسلة!',
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}