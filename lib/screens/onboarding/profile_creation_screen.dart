import 'package:flutter/material.dart';
import '../../data/languages.dart';
import '../../models/coach.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/media.dart';
import '../../widgets/spark_button.dart';
import '../you/profile_coach_screen.dart';

/// Your profile — onboarding and "Edit profile" share this screen. Starts
/// from what you saved; everything here is optional except one photo, and
/// all of it can be changed any time. Publish saves, then leaves.
class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key, required this.onPublished});

  final VoidCallback onPublished;

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _prefs = Services.prefs;
  late final List<String> _media = [..._prefs.photos];
  late String? _videoIntro = _prefs.videoIntro;
  late String? _voiceIntro = _prefs.voiceIntro;
  late final _bio = TextEditingController(text: _prefs.bio);
  late final _boundaries = TextEditingController(text: _prefs.boundaries);
  late final Map<String, TextEditingController> _answers = {
    for (final e in _prefs.promptAnswers.entries) e.key: TextEditingController(text: e.value)
  };
  late final Set<String> _languages = {..._prefs.languages};
  late final Set<String> _interests = {..._prefs.interests};
  late final Set<String> _lifestyle = {..._prefs.lifestyle};
  final _ownInterest = TextEditingController();

  static const _promptOptions = [
    'Two truths and a lie…',
    'My ideal first plan is…',
    'A skill I’m weirdly good at…',
    'The way to my heart is…',
    'I’m currently obsessed with…',
    'Ask me about…',
    'My most irrational fear…',
    'We’ll get along if…',
  ];
  static const _lifestyleOptions = [
    'Non-smoker', 'Drinks socially', 'Never drinks', 'Vegetarian', 'Vegan',
    'Gym regular', 'Dog person', 'Cat person', 'Early bird', 'Night owl',
  ];
  static const _maxMedia = 9;

  bool get _canPublish => _media.isNotEmpty;

  @override
  void dispose() {
    _bio.dispose();
    _boundaries.dispose();
    _ownInterest.dispose();
    for (final c in _answers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addMedia() async {
    final item = await chooseMedia(context);
    if (item != null && mounted) setState(() => _media.add(item));
  }

  void _mediaOptions(int i) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (isVideo(_media[i]))
            Padding(padding: const EdgeInsets.all(12), child: SizedBox(height: 260, child: VideoClip(_media[i]))),
          if (i > 0)
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Make it your first'),
              onTap: () {
                setState(() => _media.insert(0, _media.removeAt(i)));
                Navigator.pop(s);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Remove'),
            onTap: () {
              setState(() => _media.removeAt(i));
              Navigator.pop(s);
            },
          ),
        ]),
      ),
    );
  }

  void _save() {
    _prefs
      ..photos = [..._media]
      ..videoIntro = _videoIntro
      ..voiceIntro = _voiceIntro
      ..bio = _bio.text.trim()
      ..boundaries = _boundaries.text.trim()
      ..promptAnswers = {
        for (final e in _answers.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim()
      }
      ..languages = _languages.toList()
      ..interests = _interests.toList()
      ..lifestyle = _lifestyle.toList()
      ..save();
  }

  void _publish() {
    _save();
    widget.onPublished();
  }

  Future<void> _openCoach() async {
    final draft = await Navigator.of(context).push<CoachDraft>(MaterialPageRoute(
      builder: (_) => ProfileCoachScreen(
        hasBio: _bio.text.trim().isNotEmpty,
        interestCount: _interests.length,
        promptCount: _answers.values.where((c) => c.text.trim().isNotEmpty).length,
      ),
    ));
    if (draft == null || !mounted) return;
    setState(() {
      if (draft.bio != null) _bio.text = draft.bio!;
      _interests.addAll(draft.interests);
      draft.promptAnswers.forEach((k, v) => (_answers[k] ??= TextEditingController()).text = v);
    });
  }

  Future<void> _pickLanguages() async {
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LanguagePicker(initial: _languages),
    );
    if (picked != null) {
      setState(() => _languages
        ..clear()
        ..addAll(picked));
    }
  }

  void _addOwnInterest() {
    final v = cleanInterest(_ownInterest.text);
    if (v == null) return;
    setState(() {
      _interests.add(v);
      _ownInterest.clear();
    });
  }

  Widget _chips(Iterable<String> options, Set<String> selected) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final o in options)
            FilterChip(
              label: Text(o),
              selected: selected.contains(o),
              selectedColor: AppColors.blush,
              onSelected: (on) => setState(() => on ? selected.add(o) : selected.remove(o)),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gap = const SizedBox(height: 18);
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text('Show them you ✨', style: t.headlineMedium),
          const SizedBox(height: 6),
          Text('Only one photo is needed. Everything else is optional, and you can change it any time.',
              style: t.bodyMedium),
          const SizedBox(height: 12),
          SparkButton(
            label: 'Fill it in with AI — just chat',
            icon: Icons.auto_awesome,
            secondary: true,
            onPressed: _openCoach,
          ),
          gap,
          Text('Photos & videos', style: t.titleMedium),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.8),
            itemCount: (_media.length + 1).clamp(1, _maxMedia),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: i < _media.length
                  ? GestureDetector(onTap: () => _mediaOptions(i), child: MediaTile(_media[i]))
                  : InkWell(
                      onTap: _addMedia,
                      child: Container(
                        color: AppColors.emberCrimson.withValues(alpha: 0.12),
                        child: const Icon(Icons.add_a_photo_outlined),
                      ),
                    ),
            ),
          ),
          gap,
          Text('Video intro', style: t.titleMedium),
          const SizedBox(height: 8),
          GlassContainer(
            child: _videoIntro == null
                ? Row(children: [
                    Expanded(child: Text('Up to 30 seconds. Just say hi.', style: t.bodyMedium)),
                    FilledButton.icon(
                      onPressed: () async {
                        final v = await recordVideo();
                        if (v != null) setState(() => _videoIntro = v);
                      },
                      icon: const Icon(Icons.videocam),
                      label: const Text('Record'),
                    ),
                  ])
                : Column(children: [
                    SizedBox(height: 280, child: VideoClip(_videoIntro!, key: ValueKey(_videoIntro))),
                    Wrap(spacing: 8, children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final v = await recordVideo();
                          if (v != null) setState(() => _videoIntro = v);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retake'),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _videoIntro = null),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ]),
                  ]),
          ),
          gap,
          Text('Voice intro', style: t.titleMedium),
          const SizedBox(height: 8),
          GlassContainer(
            child: VoiceRecorderCard(
              path: _voiceIntro,
              onChanged: (p) => setState(() => _voiceIntro = p),
            ),
          ),
          gap,
          Text('Bio', style: t.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _bio,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: 'What makes you, you…',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
          Text('Prompts', style: t.titleMedium),
          Text('Pick a question and answer it. People can heart or reply to your answer — the easiest way to start a chat.',
              style: t.bodySmall),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final p in _promptOptions)
              FilterChip(
                label: Text(p),
                selected: _answers.containsKey(p),
                selectedColor: AppColors.blush,
                onSelected: (on) => setState(() {
                  if (on && _answers.length < 3) {
                    _answers[p] = TextEditingController();
                  } else if (!on) {
                    _answers.remove(p)?.dispose();
                  }
                }),
              ),
          ]),
          for (final e in _answers.entries)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: e.value,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: e.key,
                  hintText: 'Your answer',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                ),
              ),
            ),
          gap,
          Row(children: [
            Expanded(child: Text('Languages', style: t.titleMedium)),
            TextButton.icon(onPressed: _pickLanguages, icon: const Icon(Icons.search), label: const Text('Add')),
          ]),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final l in _languages)
              InputChip(label: Text(l), onDeleted: () => setState(() => _languages.remove(l))),
          ]),
          gap,
          Text('Interests', style: t.titleMedium),
          const SizedBox(height: 6),
          _chips({...knownInterests, ..._interests}, _interests),
          const SizedBox(height: 8),
          TextField(
            controller: _ownInterest,
            onSubmitted: (_) => _addOwnInterest(),
            decoration: InputDecoration(
              hintText: 'Add your own — anything you love',
              suffixIcon: IconButton(icon: const Icon(Icons.add), tooltip: 'Add interest', onPressed: _addOwnInterest),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
          gap,
          Text('Lifestyle', style: t.titleMedium),
          const SizedBox(height: 6),
          _chips(_lifestyleOptions, _lifestyle),
          gap,
          Text('My boundaries', style: t.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _boundaries,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Public places first, please.',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
          const SizedBox(height: 22),
          SparkButton(
            label: 'Save & go',
            icon: Icons.favorite,
            onPressed: _canPublish ? _publish : null,
          ),
          if (!_canPublish)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Add one photo to continue.', style: t.bodySmall, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

/// Search the world's languages, pick as many as you speak.
class _LanguagePicker extends StatefulWidget {
  const _LanguagePicker({required this.initial});
  final Set<String> initial;

  @override
  State<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<_LanguagePicker> {
  late final Set<String> _sel = {...widget.initial};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = worldLanguages.where((l) => l.toLowerCase().contains(_q.toLowerCase())).toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search languages'),
            ),
          ),
          Expanded(
            child: ListView(children: [
              for (final l in list)
                CheckboxListTile(
                  title: Text(l),
                  value: _sel.contains(l),
                  onChanged: (on) => setState(() => on == true ? _sel.add(l) : _sel.remove(l)),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SparkButton(label: 'Done · ${_sel.length}', onPressed: () => Navigator.pop(context, _sel)),
          ),
        ]),
      ),
    );
  }
}
