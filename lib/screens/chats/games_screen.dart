import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/care.dart' show personalDeck;
import '../../models/experience.dart';
import '../../models/message.dart' show GameQuestion;
import '../../models/member.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../connect/plan_composer_screen.dart';
import '../you/paywall_screen.dart';

/// S-030 Games Hub + S-031 In-Game Play + S-032B Reveal.
///
/// All six blueprint games are here: This or That, Two Truths and a Lie,
/// Guess My Answer, Build Our Date, Music Match, Question Cards.
/// The mechanic that matters: BOTH-answer reveal — you answer, there's an
/// honest "waiting for them" beat, then answers bloom side by side. Every
/// question is skippable. Games are conversation fuel, never gambling:
/// no stakes, no paid spins, no "compatibility score" verdicts (REA §4).
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key, required this.member});

  final Member member;

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

enum _Game { thisOrThat, twoTruths, guessMyAnswer, buildOurDate, musicMatch, questionCards }

class _GamesScreenState extends State<GamesScreen> {
  /// This or That built from BOTH profiles — not a fixed template.
  late final List<GameQuestion> _deck = personalDeck(
    myInterests: Services.prefs.me.interests,
    myTastes: Services.prefs.tastesOrSample,
    them: widget.member,
  );

  _Game _active = _Game.thisOrThat;

  /// Forgiving streak (sample: day 4, freeze unused). See ChemistryStreak.
  ChemistryStreak _streak = const ChemistryStreak(days: 4);
  bool _playedToday = false;

  // --- This or That (with the both-answer waiting beat, S-031) ---
  int _totIndex = 0;
  String? _totMine;
  bool _totWaiting = false;
  bool _totRevealed = false;
  Timer? _timer;

  // --- Two Truths ---
  int? _lieGuess;
  bool _lieRevealed = false;

  // --- Guess My Answer ---
  String? _guessPick;
  bool _guessRevealed = false;
  static const String _guessAnswer = 'Farmers market, then cook together';

  // --- Music Match ---
  String? _vibe;
  bool _vibeRevealed = false;
  static const List<String> _vibes = [
    'Lo-fi & rainy days',
    '2000s throwbacks',
    'Indie folk',
    'House & dance',
    'Old Bollywood',
    'Jazz standards',
  ];

  // --- Question Cards ---
  int _cardIndex = 0;
  static const List<String> _cards = [
    'What\'s a small thing that instantly improves your day?',
    'Best meal you\'ve ever had — where, and who were you with?',
    'What did you want to be at age ten?',
    'A place you\'d move to tomorrow if money didn\'t matter?',
    'What\'s your most controversial food opinion?',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _partnerPick {
    final q = _deck[_totIndex];
    return q.options[_totIndex % q.options.length];
  }

  void _answerTot(String option) {
    setState(() {
      // Playing today counts for the streak (once per day server-side).
      if (!_playedToday) {
        _streak = _streak.nextDay(active: true);
        _playedToday = true;
      }
      _totMine = option;
      _totWaiting = true; // both-answer rule: no reveal until they answer
    });
    Services.sound.flipTick();
    // Scaffold: the partner's answer "arrives" after a beat. Production:
    // realtime channel — the reveal fires only on the real second answer.
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _totWaiting = false;
        _totRevealed = true;
      });
    });
  }

  void _nextTot() {
    _timer?.cancel();
    setState(() {
      _totIndex = (_totIndex + 1) % _deck.length;
      _totMine = null;
      _totWaiting = false;
      _totRevealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: Text('Games with ${widget.member.firstName}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassContainer(
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _streak.completedByDate
                            ? 'Streak complete — you made a date!'
                            : 'Chemistry streak · Day ${_streak.days}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _streak.freezeAvailable
                            ? 'A game, voice note or plan keeps it going. Miss a day? Your free weekly freeze covers it.'
                            : 'Freeze used this week — it comes back Monday. No pressure either way.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassContainer(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlanComposerScreen(member: widget.member),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_calendar_outlined,
                    color: AppColors.sparkCoral),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Build our date',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Turn your answers into a real plan.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Pending invite (sample) — invites carry a state, not pressure.
          GlassContainer(
            child: Row(
              children: [
                const Icon(Icons.mail_outline, color: AppColors.sparkCoral),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.member.firstName} invited you to Music Match · waiting states are honest here — invites expire quietly, never with guilt copy.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _active = _Game.musicMatch),
                  child: const Text('Play'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // The hub: six game cards.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in _Game.values)
                ChoiceChip(
                  label: Text(_gameName(g)),
                  selected: _active == g,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) => setState(() => _active = g),
                ),
            ],
          ),
          const SizedBox(height: 16),
          switch (_active) {
            _Game.thisOrThat => _thisOrThat(context),
            _Game.twoTruths => _twoTruths(context),
            _Game.guessMyAnswer => _guess(context),
            _Game.buildOurDate => _buildDate(context),
            _Game.musicMatch => _music(context),
            _Game.questionCards => _cardsSection(context),
          },
          const SizedBox(height: 16),
          // Plus deck — clearly labelled, routes to the paywall honestly.
          GlassContainer(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline),
              title: const Text('Question Cards · Late-Night deck'),
              subtitle: const Text('Deeper questions. A Plus extra — the six core games are free.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Games are for getting to know a real person — no points to buy, no spins, no stakes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _gameName(_Game g) => switch (g) {
        _Game.thisOrThat => 'This or That',
        _Game.twoTruths => 'Two Truths & a Lie',
        _Game.guessMyAnswer => 'Guess My Answer',
        _Game.buildOurDate => 'Build Our Date',
        _Game.musicMatch => 'Music Match',
        _Game.questionCards => 'Question Cards',
      };

  Widget _thisOrThat(BuildContext context) {
    final question = _deck[_totIndex];
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Made for you two · from both profiles',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.sparkCoral)),
          const SizedBox(height: 4),
          Text(question.prompt, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final option in question.options) ...[
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _totRevealed && _totMine == option
                          ? AppColors.emberCrimson
                          : Theme.of(context).colorScheme.surface,
                      foregroundColor: AppColors.warmIvory,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: (_totRevealed || _totWaiting)
                        ? null
                        : () => _answerTot(option),
                    child: Text(option, textAlign: TextAlign.center),
                  ),
                ),
                if (option != question.options.last) const SizedBox(width: 10),
              ],
            ],
          ),
          if (_totWaiting) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('Waiting for ${widget.member.firstName}…',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
          if (_totRevealed) ...[
            const SizedBox(height: 14),
            Text(
              _totMine == _partnerPick
                  ? 'You both picked “$_partnerPick”. Great minds.'
                  : 'You: $_totMine · ${widget.member.firstName}: $_partnerPick — ask them why.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: _nextTot, child: const Text('Next question')),
          ] else if (!_totWaiting)
            TextButton(onPressed: _nextTot, child: const Text('Skip this one')),
        ],
      ),
    );
  }

  Widget _twoTruths(BuildContext context) {
    const round = MockData.twoTruthsRound;
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.member.firstName} says — which one is the lie?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < round.statements.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _lieRevealed
                    ? (i == round.lieIndex
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline)
                    : Icons.circle_outlined,
                color: _lieRevealed && i == round.lieIndex
                    ? AppColors.emberCrimson
                    : AppColors.sparkCoral,
              ),
              title: Text(round.statements[i]),
              onTap: _lieRevealed
                  ? null
                  : () {
                      setState(() {
                        _lieGuess = i;
                        _lieRevealed = true;
                      });
                      Services.sound.flipTick();
                    },
            ),
          if (_lieRevealed)
            Text(
              _lieGuess == round.lieIndex
                  ? 'You spotted it. The other two are gloriously true.'
                  : 'Not that one — the lie was “${round.statements[round.lieIndex]}”. Ask them about the true ones.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _guess(BuildContext context) {
    const options = [
      'Farmers market, then cook together',
      'Sleep in, brunch at noon',
      'Hike first, everything else later',
    ];
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.member.firstName}\'s ideal Sunday is… guess.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (final o in options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _guessRevealed
                    ? (o == _guessAnswer
                        ? Icons.check_circle_outline
                        : Icons.circle_outlined)
                    : Icons.circle_outlined,
                color: AppColors.sparkCoral,
              ),
              title: Text(o),
              onTap: _guessRevealed
                  ? null
                  : () => setState(() {
                        _guessPick = o;
                        _guessRevealed = true;
                      }),
            ),
          if (_guessRevealed)
            Text(
              _guessPick == _guessAnswer
                  ? 'Spot on. You\'re paying attention.'
                  : 'It was “$_guessAnswer” — now you know their Sunday.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildDate(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Build a date together — the winning combo becomes a real plan draft.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'You each secretly pick a vibe, a place type, and a time. '
            'Matches lock in; the rest you negotiate like adults.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          SparkButton(
            label: 'Start Build Our Date → plan draft',
            icon: Icons.calendar_month_outlined,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlanComposerScreen(member: widget.member),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _music(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pick the vibe that\'s most you right now.',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in _vibes)
                ChoiceChip(
                  label: Text(v),
                  selected: _vibe == v,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: _vibeRevealed
                      ? null
                      : (_) => setState(() {
                            _vibe = v;
                            _vibeRevealed = true;
                          }),
                ),
            ],
          ),
          if (_vibeRevealed) ...[
            const SizedBox(height: 12),
            Text(
              '${widget.member.firstName} picked “Indie folk” this week. '
              'Close enough to argue about playlists — the best kind of close.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardsSection(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Card ${_cardIndex + 1} of ${_cards.length}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(_cards[_cardIndex],
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SparkButton(
                  label: 'Answer in chat',
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SparkButton(
                  label: 'Next card',
                  onPressed: () => setState(
                      () => _cardIndex = (_cardIndex + 1) % _cards.length),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => setState(
                () => _cardIndex = (_cardIndex + 1) % _cards.length),
            child: const Text('Skip — no reason needed'),
          ),
        ],
      ),
    );
  }
}
