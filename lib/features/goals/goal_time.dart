import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

/// بيعرض الوقت اللي اتقضى على هدف معين من جلسات التركيز
class GoalTime extends StatelessWidget {
  final String goalId;
  const GoalTime({super.key, required this.goalId});

  Future<int> _minutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('goal_minutes');
    if (raw == null) return 0;
    final map = jsonDecode(raw) as Map;
    return (map[goalId] ?? 0) as int;
  }

  String _fmt(int m) {
    final h = m ~/ 60;
    final r = m % 60;
    if (h == 0) return '$r دقيقة';
    if (r == 0) return '$h ساعة';
    return '$h ساعة و$r دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _minutes(),
      builder: (context, snap) {
        final m = snap.data ?? 0;
        if (m == 0) return const SizedBox.shrink();
        return Text(
          '⏱ قضيتي ${_fmt(m)} على الهدف ده',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.purple,
          ),
        );
      },
    );
  }
}