import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-002 Age Gate — DOB entry, and S-002B the under-21 blocked notice.
/// Hard rules: under-21 can NEVER create an account or reach the tab bar;
/// on a block, no profile data is retained (attempt log only).
///
/// Entry is three scrollable wheels (month · day · year) starting on
/// today's date. Continue stays disabled until the member actually scrolls
/// to their birthday — today's date is a starting point, never an answer.
class AgeGateScreen extends StatefulWidget {
  const AgeGateScreen({super.key, required this.onPassed});

  /// Called only when the entered DOB proves 21+.
  final VoidCallback onPassed;

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

/// Whole years between [dob] and [today].
int ageOn(DateTime dob, DateTime today) {
  var age = today.year - dob.year;
  if (today.month < dob.month ||
      (today.month == dob.month && today.day < dob.day)) {
    age--;
  }
  return age;
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  late final DateTime _today = DateUtils.dateOnly(DateTime.now());
  late final int _firstYear = _today.year - 100;
  late int _year = _today.year;
  late int _month = _today.month;
  late int _day = _today.day;
  bool _touched = false;

  /// Blocked if this install already failed the gate and the 21st birthday
  /// hasn't arrived — a fresh screen can't be used to retry.
  late bool _blocked = Services.prefs.ageBlockedUntil != null &&
      DateTime.now().isBefore(Services.prefs.ageBlockedUntil!);

  late final FixedExtentScrollController _monthCtl =
      FixedExtentScrollController(initialItem: _month - 1);
  late final FixedExtentScrollController _dayCtl =
      FixedExtentScrollController(initialItem: _day - 1);
  late final FixedExtentScrollController _yearCtl =
      FixedExtentScrollController(initialItem: _year - _firstYear);

  @override
  void dispose() {
    _monthCtl.dispose();
    _dayCtl.dispose();
    _yearCtl.dispose();
    super.dispose();
  }

  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);
  DateTime get _dob => DateTime(_year, _month, _day);
  bool get _inFuture => _dob.isAfter(_today);
  int get _age => ageOn(_dob, _today);

  void _changed(VoidCallback update) {
    setState(() {
      update();
      _touched = true;
      if (_day > _daysInMonth) {
        _day = _daysInMonth;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_dayCtl.hasClients) _dayCtl.jumpToItem(_day - 1);
        });
      }
    });
  }

  void _continue() {
    if (!_touched || _inFuture) return;
    if (_age >= AppConfig.minimumAge) {
      widget.onPassed();
    } else {
      // NOTE: production cross-checks this DOB against the verified ID
      // (S-005/S-006). A mismatch at verification = fail + appeal path.
      Services.prefs.ageBlockedUntil =
          DateTime(_dob.year + AppConfig.minimumAge, _dob.month, _dob.day);
      Services.prefs.save();
      setState(() => _blocked = true);
    }
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onSelected,
    required String semantics,
  }) {
    return Semantics(
      label: semantics,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 40,
        diameterRatio: 1.3,
        squeeze: 1.1,
        useMagnifier: true,
        magnification: 1.12,
        selectionOverlay: const SizedBox.shrink(),
        onSelectedItemChanged: onSelected,
        children: [
          for (var i = 0; i < count; i++)
            Center(child: Text(label(i), maxLines: 1, overflow: TextOverflow.fade, softWrap: false)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (_blocked) {
      // S-002B — clear refusal, calm tone, no account created, no back
      // button (the block is persisted; retrying isn't a path).
      return GlassScaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 44),
              const SizedBox(height: 16),
              Text(
                '${AppConfig.appName} is ${AppConfig.minimumAge}+ only',
                style: text.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Thanks for your honesty. This isn\'t a "try again with a '
                'different date" thing — verification checks your real ID '
                'later anyway. We\'ll be here when you\'re ${AppConfig.minimumAge}.',
                style: text.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final pickerText = TextStyle(
      fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily ?? 'Poppins',
      fontSize: 20,
      color: text.bodyLarge?.color,
      fontWeight: FontWeight.w500,
    );
    final ok = _touched && !_inFuture && _age >= AppConfig.minimumAge;

    return GlassScaffold(
      // Scrolls on short phones; Continue stays pinned to the bottom.
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent: a soft coral glow behind the birthday mark.
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.sparkGlowGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sparkCoral.withValues(alpha: 0.45),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(Icons.cake_outlined,
                    color: AppColors.warmIvory, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            Text('When\'s your birthday?',
                style: text.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Center(
              child: Container(
                width: 48,
                height: 3,
                decoration: BoxDecoration(
                  gradient: AppColors.sparkGlowGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Use the date on your government ID — it\'s checked in the '
              'next steps.',
              style: text.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    // Selection band in Ember Crimson.
                    Center(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.emberCrimson.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.sparkCoral.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: Theme.of(context).brightness,
                        textTheme: CupertinoTextThemeData(pickerTextStyle: pickerText),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _wheel(
                              controller: _monthCtl,
                              count: 12,
                              label: (i) => _months[i],
                              semantics: 'Month',
                              onSelected: (i) => _changed(() => _month = i + 1),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _wheel(
                              controller: _dayCtl,
                              count: _daysInMonth,
                              label: (i) => '${i + 1}',
                              semantics: 'Day',
                              onSelected: (i) => _changed(() => _day = i + 1),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: _wheel(
                              controller: _yearCtl,
                              count: _today.year - _firstYear + 1,
                              label: (i) => '${_firstYear + i}',
                              semantics: 'Year',
                              onSelected: (i) => _changed(() => _year = _firstYear + i),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Live feedback accent: honest, immediate, no surprises.
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Chip(
                  key: ValueKey('$_touched$_age$_inFuture'),
                  avatar: Icon(
                    !_touched
                        ? Icons.swipe_vertical_outlined
                        : ok
                            ? Icons.check_circle
                            : Icons.info_outline,
                    size: 18,
                    color: ok ? AppColors.sparkCoral : null,
                  ),
                  label: Text(
                    !_touched
                        ? 'Scroll to your date of birth'
                        : _inFuture
                            ? 'That date is in the future'
                            : ok
                                ? 'You\'re $_age — welcome in'
                                : '${AppConfig.appName} is for ${AppConfig.minimumAge}+',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 14, color: AppColors.softRose),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('Never shown on your profile.',
                      style: text.bodySmall, textAlign: TextAlign.center),
                ),
              ],
            ),
            const Spacer(),
            SparkButton(
              label: 'Continue',
              icon: Icons.arrow_forward,
              iconAtEnd: true,
              onPressed: _touched && !_inFuture ? _continue : null,
            ),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }
}
