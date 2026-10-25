import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import 'reward_plan.dart';

enum _Phase { loading, intro, quiz, result }

class _Q {
  final bool personal;
  final String text;
  final List<String> options;
  final List<int>? scores; // 100 = أفضل حالة، وبدون scores = سؤال مش بيتحسب
  const _Q(this.personal, this.text, this.options, [this.scores]);
}

// أرقام الأسئلة
const _mood = 0, _sleepTime = 1, _sleepQ = 2, _meTime = 3, _support = 4;
const _phone = 5, _topApp = 6, _focusH = 7, _procrast = 8, _studyFeel = 9;
const _plan = 10, _distract = 11;
const _studyStart = 7; // أول سؤال في قسم الدراسة

const _questions = <_Q>[
  _Q(true, 'إحساسك العام الأيام اللي فاتت عامل إزاي؟', [
    'مرتاحة وهادية',
    'كويسة، بس بتوتر أحياناً',
    'مضغوطة ومتوترة أغلب الوقت',
    'مرهقة والأيام تقيلة عليا',
  ], [100, 70, 35, 10]),
  _Q(true, 'بتنامي الساعة كام عادةً؟', [
    'قبل 11 بليل',
    'من 11 لـ 1 بعد نص الليل',
    'من 1 لـ 3 الفجر',
    'بعد 3 الفجر',
  ], [100, 70, 35, 10]),
  _Q(true, 'لما بتصحي، بتحسي إنك ارتحتي؟', [
    'أيوه، بصحى نشيطة',
    'نص نص',
    'نادراً',
    'لأ، بصحى مرهقة',
  ], [100, 65, 35, 10]),
  _Q(true, 'بتلاقي وقت لنفسك؟ (راحة، هواية، خروج، أي حاجة بتحبيها)', [
    'كل يوم تقريباً',
    'كذا مرة في الأسبوع',
    'نادراً',
    'تقريباً مفيش',
  ], [100, 70, 35, 10]),
  _Q(true, 'لما بتتضايقي، بتتكلمي مع حد قريب منك؟', [
    'أيوه، دايماً',
    'أحياناً',
    'نادراً',
    'بكتم جوايا',
  ], [100, 70, 35, 10]),
  _Q(true, 'بتقعدي على الموبايل قد إيه في اليوم؟', [
    'أقل من ساعتين',
    'من 2 لـ 4 ساعات',
    'من 4 لـ 6 ساعات',
    'أكتر من 6 ساعات',
  ], [100, 75, 40, 10]),
  _Q(true, 'إيه أكتر حاجة على الموبايل بتسرق وقتك؟', [
    'السوشيال ميديا',
    'الفيديوهات (يوتيوب / تيك توك)',
    'الألعاب',
    'الشات والمحادثات',
  ]),
  _Q(false, 'بتذاكري أو بتشتغلي بتركيز كام ساعة في اليوم؟', [
    'أكتر من 3 ساعات',
    'من 2 لـ 3 ساعات',
    'من ساعة لساعتين',
    'أقل من ساعة',
  ], [100, 75, 45, 15]),
  _Q(false, 'بتأجلي مذاكرتك أو شغلك؟', [
    'نادراً',
    'أحياناً',
    'كتير',
    'دايماً',
  ], [100, 65, 30, 10]),
  _Q(false, 'إحساسك إيه لما بتقعدي تذاكري؟', [
    'مرتاحة ومهتمة',
    'عادي',
    'متوترة وقلقانة',
    'بحس إني عايزة أهرب منها',
  ], [100, 70, 35, 10]),
  _Q(false, 'عندك خطة أو جدول بتمشي عليه؟', [
    'أيوه وبلتزم بيه',
    'عندي خطة بس بلتزم أحياناً',
    'بذاكر من غير خطة',
    'لأ خالص',
  ], [100, 70, 40, 15]),
  _Q(false, 'إيه أكتر حاجة بتشتتك وقت المذاكرة؟', [
    'مفيش حاجة تقريباً',
    'أفكاري وقلقي',
    'التعب والنعاس',
    'الموبايل والسوشيال',
  ], [100, 40, 40, 15]),
];

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF2E9E6B);
  static const _orange = Color(0xFFE08A1E);
  static const _rose = Color(0xFFD9637C);

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  _Phase _phase = _Phase.loading;
  List<int?> _answers = List<int?>.filled(_questions.length, null);
  int _step = 0;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  // ---------- التخزين ----------
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final json = prefs.getString('discovery_v2');
    List<int?>? saved;
    if (json != null) {
      final m = jsonDecode(json) as Map;
      final list = (m['answers'] as List).map((e) => e as int?).toList();
      if (list.length == _questions.length && !list.contains(null)) {
        saved = list;
      }
    }
    if (!mounted) return;
    setState(() {
      _name = name;
      if (saved != null) {
        _answers = saved;
        _phase = _Phase.result;
      } else {
        _phase = _Phase.intro;
      }
    });
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('discovery_v2', jsonEncode({'answers': _answers}));
    if (!mounted) return;
    setState(() => _phase = _Phase.result);
  }

  void _retake() {
    setState(() {
      _answers = List<int?>.filled(_questions.length, null);
      _step = 0;
      _phase = _Phase.intro;
    });
  }

  // ---------- الحسابات ----------
  int _sectionScore(bool personal) {
    int sum = 0;
    int n = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.personal != personal || q.scores == null) continue;
      sum += q.scores![_answers[i]!];
      n++;
    }
    return n == 0 ? 0 : (sum / n).round();
  }

  String _label(int s) {
    if (s >= 80) return 'متوازنة ومرتاحة 🌿';
    if (s >= 60) return 'كويسة وفيها مجال للتحسن 💪';
    if (s >= 40) return 'محتاجة اهتمام وخطوات صغيرة 🌱';
    return 'الفترة دي تقيلة، وهنخففها خطوة خطوة 💜';
  }

  _Report _buildReport() {
    final a = _answers.map((e) => e!).toList();
    final p = _sectionScore(true);
    final s = _sectionScore(false);
    final app = _questions[_topApp].options[a[_topApp]];

    // اللي شغال كويس
    final keep = <String>[];
    if (a[_mood] <= 1) keep.add('إحساسك العام مستقر، وده أساس كويس لكل حاجة تانية');
    if (a[_sleepTime] <= 1) keep.add('مواعيد نومك منتظمة');
    if (a[_sleepQ] <= 1) keep.add('بتصحي مرتاحة نسبياً');
    if (a[_meTime] <= 1) keep.add('بتخصصي وقت لنفسك، كمّلي على كده');
    if (a[_support] <= 1) keep.add('عندك حد بتتكلمي معاه، وده سند كبير');
    if (a[_phone] <= 1) keep.add('استخدامك للموبايل معقول');
    if (a[_focusH] <= 1) keep.add('وقت تركيزك كويس');
    if (a[_procrast] <= 1) keep.add('نسبة التسويف عندك قليلة');
    if (a[_studyFeel] <= 1) keep.add('علاقتك بالمذاكرة مريحة');
    if (a[_plan] <= 1) keep.add('عندك خطة وبتلتزمي بيها');
    if (a[_distract] == 0) keep.add('مفيش حاجة بتشتتك وقت المذاكرة تقريباً');
    if (keep.isEmpty) {
      keep.add('إنك قعدتي مع نفسك وجاوبتي بصراحة، ده نفسه خطوة قوية 💜');
    }

    // اللي محتاج تعديل
    final change = <String>[];
    if (a[_mood] >= 2) change.add('إحساسك العام تقيل الفترة دي، اهتمي بنفسك وخدي بريك حقيقي من الضغط');
    if (a[_sleepTime] >= 2) change.add('ميعاد نومك متأخر، حاولي تقدّميه 30 دقيقة كل كام يوم');
    if (a[_sleepQ] >= 2) change.add('نومك مش بيريّحك، جربي تثبّتي ميعاد النوم والصحيان');
    if (a[_meTime] >= 2) change.add('خصصي 15 – 20 دقيقة كل يوم لحاجة بتحبيها من غير أي هدف');
    if (a[_support] >= 2) change.add('حاولي تفتحي قلبك مع حد قريب منك، الكلام بيخفف الحمل');
    if (a[_phone] >= 2) change.add('قلّلي وقت الموبايل بالتدريج، ابدأي بساعة أقل في اليوم');
    if (a[_focusH] >= 2) change.add('زوّدي وقت التركيز بالتدريج، ابدأي بجلسة 25 دقيقة');
    if (a[_procrast] >= 2) change.add('ابدأي بخطوة صغيرة 5 دقايق بس، البداية هي أصعب جزء');
    if (a[_studyFeel] >= 2) change.add('قسّمي المذاكرة لأجزاء صغيرة وخدي بريك بين كل جلسة');
    if (a[_plan] >= 2) change.add('اكتبي جدولك في تاب Plan، الخطة بتقلل التوتر');
    if (a[_distract] == 1) change.add('لما أفكارك تشتتك، اكتبيها في ورقة وارجعي لمذاكرتك');
    if (a[_distract] == 2) change.add('التعب بيشتتك، نظّمي نومك وخدي بريكات قصيرة');
    if (a[_distract] == 3) change.add('الموبايل بيشتتك، فعّلي Focus Mode وبعّديه عنك');
    if (change.isEmpty) {
      change.add('مفيش حاجة كبيرة محتاجة تتغير دلوقتي، حافظي على توازنك');
    }

    // اللي تسيبيه أو تقلليه
    final letGo = <String>[];
    if (a[_phone] >= 2 || a[_sleepTime] >= 2) letGo.add('الموبايل في السرير قبل النوم');
    if (a[_sleepTime] >= 2) letGo.add('السهر المتأخر من غير سبب');
    if (a[_phone] >= 2) letGo.add('الوقت الطويل على: $app');
    if (a[_procrast] >= 2) letGo.add('انتظار "المود المناسب" عشان تبدئي');
    if (a[_studyFeel] >= 2 || a[_mood] >= 2) letGo.add('لوم نفسك على التقصير، اللوم بيتعب ومش بيحل');
    if (a[_support] >= 3) letGo.add('كتم مشاعرك لوحدك');
    if (a[_distract] == 3) letGo.add('الموبايل جنب إيدك وقت المذاكرة');
    if (a[_plan] == 3) letGo.add('المذاكرة من غير خطة');
    if (letGo.isEmpty) {
      letGo.add('مفيش حاجة لازم تسيبيها دلوقتي، كمّلي بنفس الروح 💜');
    }

    // أول 3 خطوات صغيرة (من أضعف نقطة)
    final cands = <MapEntry<int, String>>[];
    void cand(int q, String text) {
      final sc = _questions[q].scores![a[q]];
      if (sc < 65) cands.add(MapEntry(sc, text));
    }

    cand(_mood, 'خدي 10 دقايق هدوء، وتنفّسي بعمق من غير موبايل');
    cand(_sleepTime, 'سيبي الموبايل بعيد عنك قبل النوم بنص ساعة');
    cand(_sleepQ, 'ثبّتي ميعاد صحيانك بكرة');
    cand(_meTime, 'خصصي 15 دقيقة لحاجة بتحبيها');
    cand(_support, 'كلمي حد قريب منك ولو في موضوع بسيط');
    cand(_phone, 'قلّلي الموبايل ساعة واحدة بس');
    cand(_focusH, 'اعملي جلسة Focus Mode 25 دقيقة');
    cand(_procrast, 'ابدأي بمهمة واحدة 5 دقايق بس');
    cand(_studyFeel, 'قسّمي أصعب حاجة في مذاكرتك لأجزاء صغيرة');
    cand(_plan, 'ضيفي مهمة واحدة في تاب Plan');
    cands.sort((x, y) => x.key.compareTo(y.key));
    final steps = cands.take(3).map((e) => e.value).toList();
    if (steps.isEmpty) {
      steps.add('كمّلي على روتينك، وجربي Focus Mode عشان تزوّدي تركيزك');
    }

    // ملخص الحالة
    final goodP = p >= 65;
    final goodS = s >= 65;
    String summary;
    if (goodP && goodS) {
      summary =
      'حالتك العامة مستقرة ومتوازنة، راحتك ودراستك ماشيين كويس. اللي محتاجاه بس إنك تحافظي على اللي بتعمليه وتحسّني تفاصيل صغيرة.';
    } else if (goodP) {
      summary =
      'إنتي مرتاحة نسبياً من ناحية نفسيتك وعاداتك اليومية، والتحدي الأكبر دلوقتي في تنظيم دراستك وتركيزك.';
    } else if (goodS) {
      summary =
      'دراستك ماشية كويس، لكن راحتك ونومك وعاداتك اليومية محتاجين اهتمام أكتر. خدي بالك من نفسك، لأن التركيز بيبدأ من الراحة.';
    } else {
      summary =
      'واضح إن الفترة دي تقيلة عليكي، سواء على نفسيتك أو دراستك، وده مش معناه إن فيكي حاجة غلط. محتاجة بس خطوات صغيرة وثابتة، وهنمشيها معاكي واحدة واحدة.';
    }

    final needSupport = a[_mood] == 3 ||
        (a[_mood] >= 2 && a[_support] >= 2 && a[_sleepQ] >= 2);

    return _Report(summary, keep, change, letGo, steps, needSupport);
  }

  // ---------- عناصر الواجهة ----------
  Widget _lotus() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _breath, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.75),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.18),
              blurRadius: 30,
              spreadRadius: 6,
            ),
          ],
        ),
        child: const Icon(Icons.spa, size: 72, color: AppColors.purple),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _listCard(String title, IconData icon, Color color, List<String> items,
      {bool numbered = false}) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  numbered
                      ? CircleAvatar(
                    radius: 11,
                    backgroundColor: color,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white)),
                  )
                      : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(Icons.circle, size: 7, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[i],
                      style: const TextStyle(
                          fontSize: 15, height: 1.6, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _option(String text, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected ? AppColors.purpleLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.purple : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.purple : Colors.black26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBar(String label, int v) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v / 100,
                minHeight: 6,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$v%',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // ---------- الشاشات ----------
  Widget _intro() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _lotus(),
            const SizedBox(height: 28),
            Text(
              _name.isEmpty ? 'أهلاً بيكي 🌿' : 'أهلاً يا $_name 🌿',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 14),
            const Text(
              'خدي نفس عميق... وارتاحي.\n'
                  'هنتكلم شوية عنك وعن دراستك، بهدوء وعلى راحتك.\n'
                  'مفيش إجابة صح أو غلط، جاوبي بصراحة اللي حاساه فعلاً.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.9, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text('حوالي 3 دقايق',
                style: TextStyle(fontSize: 12, color: Colors.black45)),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => setState(() => _phase = _Phase.quiz),
              child: const Text('ابدئي براحتك'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quiz() {
    final q = _questions[_step];
    final selected = _answers[_step];
    final isLast = _step == _questions.length - 1;
    final newSection = _step == 0 || _step == _studyStart;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Icon(Icons.spa, color: AppColors.purple, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _questions.length,
                  minHeight: 6,
                  color: AppColors.purple,
                  backgroundColor: Colors.white70,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('${_step + 1}/${_questions.length}',
                style: const TextStyle(color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Column(
            key: ValueKey(_step),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: q.personal ? AppColors.purpleLight : AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  q.personal ? 'عنك إنتي 🌿' : 'دراستك 📚',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                ),
              ),
              const SizedBox(height: 12),
              if (newSection)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    q.personal
                        ? 'هنبدأ بيكي إنتي: إحساسك، ونومك، وراحتك.'
                        : 'تمام، دلوقتي نتكلم عن دراستك وتركيزك.',
                    style: const TextStyle(
                        color: Colors.black54, fontStyle: FontStyle.italic),
                  ),
                ),
              Text(
                q.text,
                style: const TextStyle(
                    fontSize: 20,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < q.options.length; i++)
                _option(q.options[i], selected == i,
                        () => setState(() => _answers[_step] = i)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: selected == null
              ? null
              : () {
            if (isLast) {
              _finish();
            } else {
              setState(() => _step++);
            }
          },
          child: Text(isLast ? 'شوفي تقريرك' : 'Next'),
        ),
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: const Text('رجوع'),
          ),
      ],
    );
  }

  Widget _result() {
    final r = _buildReport();
    final p = _sectionScore(true);
    final s = _sectionScore(false);
    final total = ((p + s) / 2).round();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Row(
          children: [
            Icon(Icons.spa, color: AppColors.purple),
            SizedBox(width: 8),
            Text('تقريرك الشخصي',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 6),
        const Text('تقرير بسيط مبني على إجاباتك، اقريه براحتك 🌿',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),

        // الدرجة
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.purple,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: total / 100,
                        strokeWidth: 9,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    Text('$total%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Focus Score',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(_label(total),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    _miniBar('راحتك', p),
                    _miniBar('دراستك', s),
                  ],
                ),
              ),
            ],
          ),
        ),

        // حالتك بشكل عام
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite, color: AppColors.purple),
                  SizedBox(width: 8),
                  Text('حالتك بشكل عام',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink)),
                ],
              ),
              const SizedBox(height: 10),
              Text(r.summary,
                  style: const TextStyle(
                      fontSize: 15, height: 1.7, color: AppColors.ink)),
            ],
          ),
        ),

        _listCard('اللي شغال كويس وكمّلي عليه', Icons.check_circle, _green,
            r.keep),
        _listCard('محتاج تعدّليه', Icons.tune, _orange, r.change),
        _listCard('حاجات يفضل تسيبيها أو تقلليها',
            Icons.do_not_disturb_on_outlined, _rose, r.letGo),
        RewardPlan(steps: r.steps),

        if (r.needSupport)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite, color: Color(0xFF4A7FC1)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'لو الإحساس بالتعب أو الضغط مستمر معاكي من فترة، مش لازم تشيليه لوحدك. كلمي حد بتثقي فيه، أو فكّري تتكلمي مع مختص نفسي. ده مش ضعف، ده اهتمام بنفسك 💜',
                    style: TextStyle(
                        fontSize: 15, height: 1.7, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'الأسئلة والتقرير ده للتأمل الذاتي بس، ومش بديل عن تشخيص أو استشارة مختص نفسي.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.6),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _retake,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: AppColors.purple,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('أعيدي الأسئلة'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_phase) {
      case _Phase.loading:
        body = const Center(child: CircularProgressIndicator());
        break;
      case _Phase.intro:
        body = _intro();
        break;
      case _Phase.quiz:
        body = _quiz();
        break;
      case _Phase.result:
        body = _result();
        break;
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1EAFB), Color(0xFFE9F5F2)],
        ),
      ),
      child: body,
    );
  }
}

class _Report {
  final String summary;
  final List<String> keep;
  final List<String> change;
  final List<String> letGo;
  final List<String> steps;
  final bool needSupport;

  const _Report(this.summary, this.keep, this.change, this.letGo, this.steps,
      this.needSupport);
}