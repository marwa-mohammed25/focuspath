import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../core/theme_filter.dart';
import '../focus/break_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _s = AppSettings.instance;

  String _name = '';
  int _target = 60;
  int _duration = 25;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = prefs.getString('user_name') ?? '';
      _target = prefs.getInt('daily_target') ?? 60;
      _duration = prefs.getInt('default_minutes') ?? 25;
      _loading = false;
    });
  }

  Future<void> _editName() async {
    final c = TextEditingController(text: _name);
    final r = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('اسمك'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(d, c.text.trim()),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (r == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', r);
    if (!mounted) return;
    setState(() => _name = r);
  }

  Future<void> _setPrefInt(String key, int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, v);
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('تمسحي كل بياناتك؟'),
        content: const Text(
            'هتتمسح الأهداف والمهام والجلسات والنجوم والصور ونتيجة الأسئلة، ومش هينفع ترجعيها.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('لأ، سيبيها')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('أيوه، امسحي')),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _s.load();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('تم المسح ✅'),
        content: const Text(
            'عشان كل الشاشات تتحدّث، اعملي Refresh للصفحة (F5) أو اقفلي التطبيق وافتحيه تاني.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('تمام')),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  // ---------- عناصر ----------
  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _chips(
      Map<int, String> opts, int selected, Future<void> Function(int) onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in opts.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: selected == e.key,
            selectedColor: AppColors.purple,
            backgroundColor: AppColors.purpleLight,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected == e.key ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) async {
              await onTap(e.key);
              if (mounted) setState(() {});
            },
          ),
      ],
    );
  }

  Widget _accentPicker() {
    const names = ['بنفسجي', 'وردي', 'أزرق', 'أخضر'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (int i = 0; i < names.length; i++)
          GestureDetector(
            onTap: () async {
              await _s.setAccent(i);
              if (mounted) setState(() {});
            },
            child: Column(
              children: [
                OriginalColors(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: ThemeFilter.accentPreview(i),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _s.accent == i
                            ? const Color(0xFF8A8A8A)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: _s.accent == i
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  names[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    _s.accent == i ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings ⚙️'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card(
            icon: Icons.person,
            color: AppColors.purple,
            title: 'اسمك',
            child: InkWell(
              onTap: _editName,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _name.isEmpty ? 'دوسي واكتبي اسمك' : _name,
                        style: TextStyle(
                          fontSize: 16,
                          color: _name.isEmpty
                              ? Colors.black38
                              : AppColors.ink,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit,
                        size: 18, color: AppColors.purple),
                  ],
                ),
              ),
            ),
          ),
          _card(
            icon: Icons.dark_mode,
            color: const Color(0xFF5B6EE8),
            title: 'الوضع',
            child: _chips(
              {0: 'فاتح ☀️', 1: 'داكن 🌙', 2: 'تلقائي 📱'},
              _s.themeMode,
              _s.setTheme,
            ),
          ),
          _card(
            icon: Icons.palette,
            color: const Color(0xFFE8739A),
            title: 'لون التطبيق',
            child: _accentPicker(),
          ),
          _card(
            icon: Icons.track_changes,
            color: const Color(0xFFE8739A),
            title: 'هدف التركيز اليومي',
            child: _chips(
              {30: '30 د', 45: '45 د', 60: '60 د', 90: '90 د', 120: '120 د'},
              _target,
                  (v) async {
                _target = v;
                await _setPrefInt('daily_target', v);
              },
            ),
          ),
          _card(
            icon: Icons.timer,
            color: const Color(0xFF4A90E2),
            title: 'مدة جلسة التركيز',
            child: _chips(
              {15: '15 د', 25: '25 د', 45: '45 د'},
              _duration,
                  (v) async {
                _duration = v;
                await _setPrefInt('default_minutes', v);
              },
            ),
          ),
          _card(
            icon: Icons.spa,
            color: const Color(0xFF2EB67D),
            title: 'بريك التنفس بعد الجلسة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chips(
                  {0: 'من غير بريك', 3: '3 د', 5: '5 د', 10: '10 د'},
                  _s.breakMin,
                  _s.setBreak,
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BreakScreen(
                          minutes: _s.breakMin == 0 ? 1 : _s.breakMin),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('جرّبي شكل البريك'),
                ),
              ],
            ),
          ),
          _card(
            icon: Icons.text_fields,
            color: const Color(0xFFF59E3D),
            title: 'حجم الخط',
            child: _chips(
              {0: 'صغير', 1: 'متوسط', 2: 'كبير'},
              _s.fontIdx,
              _s.setFont,
            ),
          ),
          _card(
            icon: Icons.favorite,
            color: const Color(0xFFE8739A),
            title: 'أسلوب الرسايل التحفيزية',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chips(
                  {0: 'لطيف 💜', 1: 'حماسي 🔥', 2: 'هادي 🌿'},
                  _s.msgStyle,
                  _s.setStyle,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blush,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Quotes.at(DateTime.now().day),
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _card(
            icon: Icons.self_improvement,
            color: const Color(0xFF9B7BDB),
            title: 'وضع الهدوء',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _s.calm,
              activeColor: AppColors.purple,
              title: const Text('من غير ضغط'),
              subtitle: const Text(
                  'بيخفي كارت النجوم والسلسلة 🔥 من الـ Home، للأيام اللي عايزة فيها تركزي من غير مقارنات.'),
              onChanged: (v) async {
                await _s.setCalm(v);
                if (mounted) setState(() {});
              },
            ),
          ),
          _card(
            icon: Icons.calendar_month,
            color: const Color(0xFF4A90E2),
            title: 'أول يوم في الأسبوع',
            child: _chips(
              {6: 'السبت', 7: 'الأحد', 1: 'الاتنين'},
              _s.weekStart,
              _s.setWeekStart,
            ),
          ),
          _card(
            icon: Icons.language,
            color: AppColors.purple,
            title: 'اللغة 🌍',
            child: const Text(
              'عربي / إنجليزي هتيجي في الخطوة الجاية، لأن كل كلمة في التطبيق محتاجة ترجمة.',
              style: TextStyle(color: Colors.black54, height: 1.6),
            ),
          ),
          _card(
            icon: Icons.delete_sweep,
            color: const Color(0xFFD64545),
            title: 'مسح البيانات',
            child: OutlinedButton(
              onPressed: _clearAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD64545),
                side: const BorderSide(color: Color(0xFFD64545)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('مسح كل بياناتي'),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Column(
              children: [
                Icon(Icons.spa, color: AppColors.purple),
                SizedBox(height: 6),
                Text(
                  'FocusPath · Less phone... More life 💜',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}