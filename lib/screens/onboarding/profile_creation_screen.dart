import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-010…S-014 Profile Creation, the full blueprint surface:
///  - S-010 photo grid: 6 slots, add/remove/reorder, per-photo moderation
///    status chip, minimum 3 to publish, first photo = the match photo
///    (Layer-3 verified against it).
///  - S-011 video intro: recorder card with timer, retake, a REQUIRED
///    captions field (accessibility rule — no captions, no publish),
///    moderation status, and an honest Skip.
///  - S-012 voice intro (P1): optional, with its own privacy note.
///  - S-013 basics / bio / prompts (pick 3, answer), languages, lifestyle,
///    boundaries — boundaries PRINT on the public profile.
///  - S-014 preview: exactly what others see, edit jump-backs, Publish.
///  - AI-03 Profile Coach stays available here and in S-043: suggestions
///    only, never auto-applied.
/// Name and age are read-only — they come from the verified ID (S-010).
class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key, required this.onPublished});

  final VoidCallback onPublished;

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  static const List<String> _samplePhotos = [
    'assets/images/hero_welcome.jpg',
    'assets/images/backdrop_discover.jpg',
    'assets/images/backdrop_match.jpg',
  ];
  final List<String?> _slots = List<String?>.filled(6, null);
  int _sampleCursor = 0;

  bool _videoRecorded = false;
  bool _videoSkipped = false;
  final TextEditingController _captions = TextEditingController();
  bool _voiceRecorded = false;

  // Edit mode: start from what was saved last time.
  final TextEditingController _bio = TextEditingController(text: Services.prefs.bio);
  final TextEditingController _boundaries =
      TextEditingController(text: Services.prefs.boundaries);
  final Map<String, TextEditingController> _promptAnswers = {
    for (final e in Services.prefs.promptAnswers.entries)
      e.key: TextEditingController(text: e.value)
  };
  late final Set<String> _prompts = {...Services.prefs.promptAnswers.keys};
  final Set<String> _languages = {...Services.prefs.languages};
  final Set<String> _lifestyle = {};

  /// Interests drive "You both", why-you're-seeing-them, games built for
  /// two, and plan suggestions — so they're asked here, not guessed.
  late final Set<String> _interests = {...Services.prefs.interests};
  static const List<String> _interestOptions = [
    'Coffee', 'Live music', 'Hiking', 'Ceramics', 'Yoga', 'Kayaking',
    'Board games', 'Cooking', 'Photography', 'Farmers markets', 'Bouldering',
    'Jazz', 'Comedy shows', 'Trail running', 'Book clubs', 'Travel',
  ];

  bool _coachLoading = false;
  List<String> _coachTips = const [];

  static const List<String> _promptOptions = [
    'Two truths and a lie…',
    'My ideal first plan is…',
    'A skill I\'m weirdly good at…',
    'The way to my heart is…',
    'I\'m currently obsessed with…',
    'Ask me about…',
  ];
  static const List<String> _languageOptions = [
    'English',
    'Spanish',
    'Hindi',
    'Telugu',
    'French',
    'Portuguese',
  ];
  static const List<String> _lifestyleOptions = [
    'Non-smoker',
    'Drinks socially',
    'Never drinks',
    'Vegetarian',
    'Gym regular',
    'Dog person',
    'Early bird',
    'Night owl',
  ];

  int get _photoCount => _slots.where((s) => s != null).length;
  bool get _canPublish =>
      _photoCount >= 3 &&
      (!_videoRecorded || _captions.text.trim().isNotEmpty);

  @override
  void dispose() {
    _captions.dispose();
    _bio.dispose();
    _boundaries.dispose();
    for (final c in _promptAnswers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _coach() async {
    if (!Services.prefs.aiProfileCoach) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile coach is off. Turn it on in Privacy Centre → AI features.')));
      return;
    }
    setState(() => _coachLoading = true);
    final tips = await Services.ai.profileCoachTips();
    if (!mounted) return;
    setState(() {
      _coachLoading = false;
      _coachTips = tips;
    });
  }

  void _photoTap(int i) {
    if (_slots[i] == null) {
      setState(() {
        _slots[i] = _samplePhotos[_sampleCursor % _samplePhotos.length];
        _sampleCursor++;
      });
      return;
    }
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Make main photo'),
            subtitle: const Text(
                'Your main photo is the one matched to your ID (Layer 3).'),
            onTap: () {
              setState(() {
                final tmp = _slots[0];
                _slots[0] = _slots[i];
                _slots[i] = tmp;
              });
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Move later'),
            onTap: () {
              if (i < 5) {
                setState(() {
                  final tmp = _slots[i + 1];
                  _slots[i + 1] = _slots[i];
                  _slots[i] = tmp;
                });
              }
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Remove photo'),
            onTap: () {
              setState(() => _slots[i] = null);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text('Your profile — video first, always honest.',
              style: text.headlineMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.emberCrimson.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Name & age come from your verified ID and can\'t be '
                    'edited here — that\'s what the badge means.',
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Photos · $_photoCount of 6 (min 3)', style: text.titleMedium),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: 6,
            itemBuilder: (context, i) {
              final asset = _slots[i];
              return GestureDetector(
                onTap: () => _photoTap(i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (asset != null)
                        Image.asset(asset, fit: BoxFit.cover)
                      else
                        Container(
                          color: AppColors.emberCrimson.withValues(alpha: 0.12),
                          child: const Icon(Icons.add_a_photo_outlined),
                        ),
                      if (asset != null)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(i == 0 ? 'Main · Checked' : 'Approved',
                                style: const TextStyle(fontSize: 9)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          Text(
            'Every photo passes moderation before it\'s public; your main '
            'photo must match your verified ID photo.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 18),
          Text('Video intro · up to 30s', style: text.titleMedium),
          const SizedBox(height: 8),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _videoRecorded
                          ? Icons.check_circle
                          : Icons.videocam_outlined,
                      color: AppColors.sparkCoral,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _videoRecorded
                            ? 'Recorded · 0:18 · Moderation: Approved'
                            : 'Say hi like you would in person. It plays first on your card.',
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_videoSkipped && !_videoRecorded)
                  Row(
                    children: [
                      Expanded(
                        child: Text('Skipped — add a video intro any time from You → Edit profile.',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _videoSkipped = false),
                        child: const Text('Add now'),
                      ),
                    ],
                  )
                else if (!_videoRecorded)
                  Row(
                    children: [
                      Expanded(
                        child: SparkButton(
                          label: 'Record',
                          icon: Icons.fiber_manual_record,
                          onPressed: () =>
                              setState(() => _videoRecorded = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SparkButton(
                          label: 'Skip for now',
                          secondary: true,
                          onPressed: () => setState(() => _videoSkipped = true),
                        ),
                      ),
                    ],
                  )
                else ...[
                  TextField(
                    controller: _captions,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Captions (required with video)',
                      hintText: 'Type what you say, word for word…',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _videoRecorded = false),
                    child: const Text('Retake'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Voice intro · optional', style: text.titleMedium),
          const SizedBox(height: 8),
          GlassContainer(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_voiceRecorded ? Icons.stop_circle : Icons.mic),
                  color: AppColors.sparkCoral,
                  onPressed: () =>
                      setState(() => _voiceRecorded = !_voiceRecorded),
                ),
                Expanded(
                  child: Text(
                    _voiceRecorded
                        ? 'Recorded · 0:12'
                        : 'Ten seconds of your voice. Plays only on your profile — never in search.',
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Bio', style: text.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _bio,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: 'Work, obsessions, the real stuff…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Prompts · pick up to 3', style: text.titleMedium),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in _promptOptions)
                FilterChip(
                  label: Text(p),
                  selected: _prompts.contains(p),
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      if (_prompts.length < 3) {
                        _prompts.add(p);
                        _promptAnswers[p] = TextEditingController();
                      }
                    } else {
                      _prompts.remove(p);
                    }
                  }),
                ),
            ],
          ),
          for (final p in _prompts)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _promptAnswers[p],
                decoration: InputDecoration(
                  labelText: p,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Text('Languages', style: text.titleMedium),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final l in _languageOptions)
                FilterChip(
                  label: Text(l),
                  selected: _languages.contains(l),
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (sel) => setState(() {
                    sel ? _languages.add(l) : _languages.remove(l);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Interests · pick up to 8', style: text.titleMedium),
          Text('These power "You both", games and plan ideas.', style: text.bodySmall),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final i in _interestOptions)
                FilterChip(
                  label: Text(i),
                  selected: _interests.contains(i),
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (sel) => setState(() {
                    if (!sel) {
                      _interests.remove(i);
                    } else if (_interests.length < 8) {
                      _interests.add(i);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Lifestyle', style: text.titleMedium),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final l in _lifestyleOptions)
                FilterChip(
                  label: Text(l),
                  selected: _lifestyle.contains(l),
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (sel) => setState(() {
                    sel ? _lifestyle.add(l) : _lifestyle.remove(l);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Boundaries · printed on your profile', style: text.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _boundaries,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Public places first. No last-minute plan changes.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18),
                    const SizedBox(width: 6),
                    Text('AI Profile Coach',
                        style: text.titleMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Suggestions only — nothing is ever changed without you.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 8),
                if (_coachTips.isEmpty)
                  SparkButton(
                    label: _coachLoading ? 'Thinking…' : 'Get coach tips',
                    secondary: true,
                    onPressed: _coachLoading ? null : _coach,
                  )
                else
                  for (final tip in _coachTips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $tip', style: text.bodyMedium),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SparkButton(
            label: 'Preview profile',
            secondary: true,
            onPressed: _photoCount == 0 ? null : _openPreview,
          ),
          const SizedBox(height: 10),
          SparkButton(
            label: 'Publish profile',
            onPressed: _canPublish ? widget.onPublished : null,
          ),
          if (!_canPublish)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _photoCount < 3
                    ? 'Add at least 3 photos to publish.'
                    : 'Add captions to your video intro to publish.',
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  /// S-014 Profile Preview — the public view, with edit jump-backs.
  void _openPreview() {
    final me = MockData.members.first;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => GlassScaffold(
          appBar: AppBar(title: const Text('Preview — what people see')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  _slots.firstWhere((s) => s != null) ?? me.photoAsset,
                  fit: BoxFit.cover,
                  height: 320,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('You, 26 · ~this city',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified,
                      size: 18, color: AppColors.sparkCoral),
                ],
              ),
              if (_videoRecorded)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('▶ Video intro · 0:18 · captions on',
                      style: Theme.of(ctx).textTheme.bodyMedium),
                ),
              if (_bio.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_bio.text),
                ),
              for (final p in _prompts)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('$p ${_promptAnswers[p]?.text ?? ''}'),
                ),
              if (_boundaries.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Boundaries: ${_boundaries.text}'),
                ),
              const SizedBox(height: 16),
              SparkButton(
                label: 'Back to editing',
                secondary: true,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              const SizedBox(height: 8),
              SparkButton(
                label: 'Looks right — publish',
                onPressed: _canPublish
                    ? () {
                        Navigator.of(ctx).pop();
                        Services.prefs
                          ..bio = _bio.text.trim()
                          ..boundaries = _boundaries.text.trim()
                          ..promptAnswers = {
                            for (final p in _prompts)
                              if ((_promptAnswers[p]?.text.trim() ?? '').isNotEmpty)
                                p: _promptAnswers[p]!.text.trim()
                          }
                          ..languages = _languages.toList()
                          ..interests = _interests.toList()
                          ..save();
                        widget.onPublished();
                      }
                    : null,
              ),
              TextButton(
                // Badge explainer lives on the public preview too (S-014).
                onPressed: () => showGlassSheet<void>(
                  ctx,
                  child: Text(
                    'The badge means: real ID checked, 21+, live face, '
                    'photo match. It never means “safe person” — see the '
                    'full explainer in Trust & Safety.',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                ),
                child: const Text('What does my badge mean?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
