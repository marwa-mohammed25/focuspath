import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  int fontIdx = 1; // 0 صغير ، 1 متوسط ، 2 كبير
  int weekStart = 6; // 6 السبت ، 7 الأحد ، 1 الاتنين
  int msgStyle = 0; // 0 لطيف ، 1 حماسي ، 2 هادي
  bool calm = false;
  int breakMin = 5; // 0 = من غير بريك
  int themeMode = 0; // 0 فاتح ، 1 داكن ، 2 تلقائي
  int accent = 0; // 0 بنفسجي ، 1 وردي ، 2 أزرق ، 3 أخضر
  String lang = 'ar'; // جاهزة للجولة الجاية (اللغة)

  double get fontScale => const [0.9, 1.0, 1.15][fontIdx];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    fontIdx = p.getInt('s_font') ?? 1;
    weekStart = p.getInt('s_week') ?? 6;
    msgStyle = p.getInt('s_style') ?? 0;
    calm = p.getBool('s_calm') ?? false;
    breakMin = p.getInt('s_break') ?? 5;
    themeMode = p.getInt('s_theme') ?? 0;
    accent = p.getInt('s_accent') ?? 0;
    lang = p.getString('s_lang') ?? 'ar';
    notifyListeners();
  }

  Future<void> _putInt(String k, int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(k, v);
    notifyListeners();
  }

  Future<void> setFont(int v) {
    fontIdx = v;
    return _putInt('s_font', v);
  }

  Future<void> setWeekStart(int v) {
    weekStart = v;
    return _putInt('s_week', v);
  }

  Future<void> setStyle(int v) {
    msgStyle = v;
    return _putInt('s_style', v);
  }

  Future<void> setBreak(int v) {
    breakMin = v;
    return _putInt('s_break', v);
  }

  Future<void> setTheme(int v) {
    themeMode = v;
    return _putInt('s_theme', v);
  }

  Future<void> setAccent(int v) {
    accent = v;
    return _putInt('s_accent', v);
  }

  Future<void> setCalm(bool v) async {
    calm = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('s_calm', v);
    notifyListeners();
  }
}

/// الجمل التحفيزية حسب الأسلوب اللي اخترتيه
class Quotes {
  static const _daily = <List<String>>[
    [
      'كل خطوة صغيرة النهاردة بتقرّبك من حلمك 💜',
      'خدي وقتك، المهم إنك تكمّلي 🌿',
      'إنتي بتعملي أحسن ما عندك، وده كفاية 💜',
      'خطوة صغيرة النهاردة أحسن من مفيش 🌱',
      'اهتمي بنفسك زي ما بتهتمي بحلمك 🌸',
      'كل يوم فرصة جديدة تبدئي منها ✨',
    ],
    [
      'يلا يا بطلة! النهاردة يوم تحقيق الأهداف 🔥',
      'إنتي أقوى مما تتخيلي، كمّلي! 💪',
      'الحلم مش هيتحقق لوحده، يلا نشتغل! 🚀',
      'ركّزي دلوقتي وهتفرحي بكرة 🎯',
      'مفيش حاجة تقف قدامك، انطلقي! ⚡',
      'كل جلسة تركيز خطوة ناحية القمة 🏆',
    ],
    [
      'خدي نفس عميق، وابدئي بهدوء 🌿',
      'مش لازم تستعجلي، كل حاجة في وقتها 🍃',
      'ركّزي في اللحظة اللي إنتي فيها 🪷',
      'الهدوء بيصنع تركيز أحسن 🌊',
      'براحة وثبات، هتوصلي ✨',
      'اسمحي لنفسك ترتاحي وتكمّلي 🌸',
    ],
  ];

  static const _focus = <List<String>>[
    [
      'مستقبلك هيشكرك على اللي بتعمليه دلوقتي 💜',
      'ركّزي، شوية بس وهتفرحي بنفسك ✨',
      'كل دقيقة تركيز بتقرّبك من هدفك 🎯',
      'الموبايل هيستنى، حلمك أهم 🌸',
    ],
    [
      'كمّلي! إنتي ماشية كويس جداً 🔥',
      'ولا حاجة هتوقفك، ركّزي! 💪',
      'دقايق قليلة وتبقي خلصتي إنجاز جديد 🚀',
      'إنتي بطلة، كمّلي للآخر! 🏆',
    ],
    [
      'تنفّسي بهدوء، وكمّلي براحة 🌿',
      'ركّزي في حاجة واحدة بس دلوقتي 🪷',
      'كل نفس بيرجّعك للتركيز 🍃',
      'براحة وثبات، إنتي بخير 💜',
    ],
  ];

  static String at(int i) {
    final l = _daily[AppSettings.instance.msgStyle];
    return l[i % l.length];
  }

  static String focusAt(int i) {
    final l = _focus[AppSettings.instance.msgStyle];
    return l[i % l.length];
  }
}