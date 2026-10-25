import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/theme_filter.dart';

class _Dream {
  final String id;
  final String caption;
  final Uint8List bytes;

  const _Dream(this.id, this.caption, this.bytes);

  _Dream withCaption(String c) => _Dream(id, c, bytes);

  Map<String, dynamic> toMap() =>
      {'id': id, 'caption': caption, 'img': base64Encode(bytes)};

  factory _Dream.fromMap(Map m) =>
      _Dream(m['id'], m['caption'] ?? '', base64Decode(m['img']));
}

class VisionBoard extends StatefulWidget {
  const VisionBoard({super.key});

  @override
  State<VisionBoard> createState() => _VisionBoardState();
}

class _VisionBoardState extends State<VisionBoard> {
  static const _maxDreams = 8;
  static const _maxBytes = 1500000; // حوالي 1.5 ميجا للصورة

  List<_Dream> _dreams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('vision_board');
    List<_Dream> list = [];
    if (json != null) {
      list = (jsonDecode(json) as List)
          .map((e) => _Dream.fromMap(e as Map))
          .toList();
    }
    if (!mounted) return;
    setState(() {
      _dreams = list;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'vision_board', jsonEncode(_dreams.map((d) => d.toMap()).toList()));
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String?> _askCaption(String current) {
    final c = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('جملة تحت الصورة'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
              hintText: 'مثلاً: هبقى مهندسة أمن سيبراني'),
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
  }

  Future<void> _add() async {
    if (_dreams.length >= _maxDreams) {
      _msg('وصلتي للحد الأقصى ($_maxDreams صور)، امسحي صورة عشان تضيفي جديدة');
      return;
    }
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 75,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxBytes) {
      _msg('الصورة كبيرة قوي، اختاري صورة أصغر');
      return;
    }
    final caption = await _askCaption('');
    if (caption == null || !mounted) return;
    setState(() {
      _dreams = [
        ..._dreams,
        _Dream(DateTime.now().millisecondsSinceEpoch.toString(), caption,
            bytes),
      ];
    });
    _save();
  }

  void _open(_Dream d) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OriginalColors(child: Image.memory(d.bytes, fit: BoxFit.cover, width: double.infinity)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  d.caption.isEmpty ? 'من غير جملة' : d.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final c = await _askCaption(d.caption);
                      if (c == null || !mounted) return;
                      setState(() {
                        _dreams = [
                          for (final x in _dreams)
                            if (x.id == d.id) x.withCaption(c) else x,
                        ];
                      });
                      _save();
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('تعديل الجملة'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _dreams = _dreams.where((x) => x.id != d.id).toList();
                      });
                      _save();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('حذف'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(_Dream d) {
    return InkWell(
      onTap: () => _open(d),
      borderRadius: BorderRadius.circular(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OriginalColors(child: Image.memory(d.bytes, fit: BoxFit.cover, gaplessPlayback: true)),
              if (d.caption.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      d.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 40);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Vision Board 🌸',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink),
              ),
            ),
            IconButton(
              onPressed: _add,
              icon: const Icon(Icons.add_photo_alternate_outlined,
                  color: AppColors.purple),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_dreams.isEmpty)
          InkWell(
            onTap: _add,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 36, color: AppColors.purple),
                  SizedBox(height: 8),
                  Text('ضيفي صور أحلامك هنا',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                  SizedBox(height: 4),
                  Text(
                    'صورة لحاجة نفسك توصليلها، وجملة تفكرك ليه بدأتي 💜',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dreams.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _card(_dreams[i]),
            ),
          ),
      ]
    );
  }
}