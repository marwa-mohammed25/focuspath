import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class BreakScreen extends StatefulWidget {
  final int minutes;
  const BreakScreen({super.key, required this.minutes});

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late int _left = widget.minutes * 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left <= 1) {
        _timer?.cancel();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  String get _clock {
    final m = (_left ~/ 60).toString().padLeft(2, '0');
    final s = (_left % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1EAFB), Color(0xFFE9F5F2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'وقت البريك 🌿',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'إنتي تستاهلي ترتاحي. سيبي الموبايل وتنفّسي معايا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.6),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) {
                    final inhale = _c.status != AnimationStatus.reverse;
                    return Column(
                      children: [
                        Transform.scale(
                          scale: 0.85 + 0.3 * _c.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.spa,
                                size: 76, color: AppColors.purple),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          inhale ? 'شهيق... 🌬️' : 'زفير... 🍃',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purple,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 36),
                Text(
                  _clock,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('تخطّي البريك'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}