import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'settings.dart';

/// بيغيّر ألوان التطبيق كله (داكن / فاتح + لون التطبيق) من مكان واحد
class ThemeFilter {
  static const _hues = [0.0, 55.0, -60.0, -120.0]; // بنفسجي، وردي، أزرق، أخضر
  static const _s = 0.86;
  static const _o = 20.0;

  static final List<double> identity = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static final List<double> _invert = [
    -_s, 0, 0, 0, 255 * _s + _o,
    0, -_s, 0, 0, 255 * _s + _o,
    0, 0, -_s, 0, 255 * _s + _o,
    0, 0, 0, 1, 0,
  ];

  static final List<double> _invertBack = [
    -1 / _s, 0, 0, 0, 255 + _o / _s,
    0, -1 / _s, 0, 0, 255 + _o / _s,
    0, 0, -1 / _s, 0, 255 + _o / _s,
    0, 0, 0, 1, 0,
  ];

  // الداكن = قلب الألوان + لفّ 180 درجة عشان الألوان ترجع لدرجتها
  static final List<double> _dark = _mul(_hue(180), _invert);
  static final List<double> _darkBack = _mul(_invertBack, _hue(-180));

  static List<double> _hue(double deg) {
    final r = deg * math.pi / 180;
    final c = math.cos(r);
    final s = math.sin(r);
    return [
      0.213 + c * 0.787 - s * 0.213,
      0.715 - c * 0.715 - s * 0.715,
      0.072 - c * 0.072 + s * 0.928,
      0, 0,
      0.213 - c * 0.213 + s * 0.143,
      0.715 + c * 0.285 + s * 0.140,
      0.072 - c * 0.072 - s * 0.283,
      0, 0,
      0.213 - c * 0.213 - s * 0.787,
      0.715 - c * 0.715 + s * 0.715,
      0.072 + c * 0.928 + s * 0.072,
      0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  // a ∘ b  (بنطبّق b الأول وبعدين a)
  static List<double> _mul(List<double> a, List<double> b) {
    final r = List<double>.filled(20, 0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double v = 0;
        for (int k = 0; k < 4; k++) {
          v += a[i * 5 + k] * b[k * 5 + j];
        }
        if (j == 4) v += a[i * 5 + 4];
        r[i * 5 + j] = v;
      }
    }
    return r;
  }

  static bool isDark(BuildContext context) {
    final s = AppSettings.instance;
    if (s.themeMode == 1) return true;
    if (s.themeMode == 2) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return false;
  }

  /// الفلتر اللي بيتطبّق على التطبيق كله
  static List<double> appMatrix(bool dark, int accent) {
    final h = _hue(_hues[accent]);
    return dark ? _mul(h, _dark) : h;
  }

  /// بيرجّع الألوان الأصلية (للصور مثلاً)
  static List<double> originalMatrix(bool dark, int accent) {
    final h = _hue(-_hues[accent]);
    return dark ? _mul(_darkBack, h) : h;
  }

  /// بيلغي الداكن بس (لشاشة Focus Mode، عشان تفضل غامقة)
  static List<double> undoDarkMatrix(bool dark) => dark ? _darkBack : identity;

  /// اللون الحقيقي للبنفسجي بعد تغيير اللون (للمعاينة في الإعدادات)
  static Color accentPreview(int accent) {
    const base = [123.0, 94.0, 167.0];
    final m = _hue(_hues[accent]);
    int ch(int row) {
      final v = m[row * 5] * base[0] +
          m[row * 5 + 1] * base[1] +
          m[row * 5 + 2] * base[2];
      return v.round().clamp(0, 255).toInt();
    }

    return Color.fromARGB(255, ch(0), ch(1), ch(2));
  }
}

/// بيتحط حوالين التطبيق كله في main.dart
class AppColorFilter extends StatelessWidget {
  final Widget child;
  const AppColorFilter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final m = ThemeFilter.appMatrix(
      ThemeFilter.isDark(context),
      AppSettings.instance.accent,
    );
    return ColorFiltered(colorFilter: ColorFilter.matrix(m), child: child);
  }
}

/// بيحافظ على الألوان الأصلية لحاجة جواه (زي الصور)
class OriginalColors extends StatelessWidget {
  final Widget child;
  const OriginalColors({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final m = ThemeFilter.originalMatrix(
          ThemeFilter.isDark(context),
          AppSettings.instance.accent,
        );
        return ColorFiltered(colorFilter: ColorFilter.matrix(m), child: child);
      },
    );
  }
}

/// بيلغي الوضع الداكن على شاشة معينة (Focus Mode)
class UndoDark extends StatelessWidget {
  final Widget child;
  const UndoDark({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final m = ThemeFilter.undoDarkMatrix(ThemeFilter.isDark(context));
        return ColorFiltered(colorFilter: ColorFilter.matrix(m), child: child);
      },
    );
  }
}