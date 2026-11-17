import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../design/tokens.dart';
import '../../design/type.dart';
import '../../services/services.dart';
import '../../ui/button.dart';
import '../../ui/page.dart';

/// Figma 01.05 Birthday. Three wheels (month · day · year) start on today;
/// Continue stays off until the member scrolls to their birthday. Under 21
/// is blocked for good (persisted until the 21st birthday).
class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key, required this.onPassed});

  /// Called only when the date proves 21+.
  final VoidCallback onPassed;

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Whole years between [dob] and [today].
int ageOn(DateTime dob, DateTime today) {
  var age = today.year - dob.year;
  if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
  return age;
}

// Figma "Birthday option" rows: 58 tall, 12 apart, the middle one on blush.
const _row = 58.0;
const _gap = 12.0;

class _BirthdayScreenState extends State<BirthdayScreen> {
  late final DateTime _today = DateUtils.dateOnly(DateTime.now());
  late final int _firstYear = _today.year - 100;
  late int _year = _today.year;
  late int _month = _today.month;
  late int _day = _today.day;
  bool _touched = false;

  late bool _blocked =
      Services.prefs.ageBlockedUntil != null && DateTime.now().isBefore(Services.prefs.ageBlockedUntil!);

  late final _monthCtl = FixedExtentScrollController(initialItem: _month - 1);
  late final _dayCtl = FixedExtentScrollController(initialItem: _day - 1);
  late final _yearCtl = FixedExtentScrollController(initialItem: _year - _firstYear);

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

  void _changed(VoidCallback update) => setState(() {
        update();
        _touched = true;
        if (_day > _daysInMonth) {
          _day = _daysInMonth;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_dayCtl.hasClients) _dayCtl.jumpToItem(_day - 1);
          });
        }
      });

  void _continue() {
    if (_age >= AppConfig.minimumAge) {
      widget.onPassed();
      return;
    }
    Services.prefs.ageBlockedUntil = DateTime(_dob.year + AppConfig.minimumAge, _dob.month, _dob.day);
    Services.prefs.save();
    setState(() => _blocked = true);
  }

  Widget _wheel({
    required int flex,
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required String Function(int) label,
    required ValueChanged<int> onSelected,
    required String semantics,
  }) =>
      Expanded(
        flex: flex,
        child: Semantics(
          label: semantics,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: _row + _gap,
            diameterRatio: 100, // flat rows, as drawn
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelected,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (_, i) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label(i),
                  maxLines: 1,
                  style: i == selected ? CarinoText.wheelSelected : CarinoText.wheel,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _picker() => Container(
        padding: const EdgeInsets.all(CarinoSpace.xl),
        decoration: BoxDecoration(color: CarinoColors.soft, borderRadius: BorderRadius.circular(CarinoRadius.photo)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Figma column widths 115 / 60 / 100 with 10pt gaps, kept as ratios.
          const Row(children: [
            Expanded(flex: 115, child: Text('Month', style: CarinoText.pickerHead)),
            SizedBox(width: 10),
            Expanded(flex: 60, child: Text('Day', style: CarinoText.pickerHead)),
            SizedBox(width: 10),
            Expanded(flex: 100, child: Text('Year', style: CarinoText.pickerHead)),
          ]),
          const SizedBox(height: _gap),
          SizedBox(
            height: _row * 3 + _gap * 2,
            child: Stack(children: [
              Center(
                child: Container(
                  height: _row,
                  decoration:
                      BoxDecoration(color: CarinoColors.blush, borderRadius: BorderRadius.circular(CarinoRadius.digit)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(children: [
                  _wheel(
                    flex: 125,
                    controller: _monthCtl,
                    count: 12,
                    selected: _month - 1,
                    label: (i) => _months[i],
                    semantics: 'Month',
                    onSelected: (i) => _changed(() => _month = i + 1),
                  ),
                  _wheel(
                    flex: 70,
                    controller: _dayCtl,
                    count: _daysInMonth,
                    selected: _day - 1,
                    label: (i) => '${i + 1}',
                    semantics: 'Day',
                    onSelected: (i) => _changed(() => _day = i + 1),
                  ),
                  _wheel(
                    flex: 88,
                    controller: _yearCtl,
                    count: _today.year - _firstYear + 1,
                    selected: _year - _firstYear,
                    label: (i) => '${_firstYear + i}',
                    semantics: 'Year',
                    onSelected: (i) => _changed(() => _year = _firstYear + i),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      );

  String get _status => !_touched
      ? 'Scroll to your date of birth'
      : _inFuture
          ? 'That date is in the future.'
          : _age >= AppConfig.minimumAge
              ? 'You’ll appear as $_age on your profile.'
              : '${AppConfig.appName} is for ${AppConfig.minimumAge}+.';

  @override
  Widget build(BuildContext context) {
    if (_blocked) return const _Blocked();
    return CarinoPage(
      title: 'Your birthday',
      step: '3 / 5',
      children: [
        const Text('Celebrate\nyourself.', style: CarinoText.display),
        Text('This community is for adults ${AppConfig.minimumAge}+. Your full birthday stays private.',
            style: CarinoText.lead),
        _picker(),
        Text(_status, style: CarinoText.small),
        CarinoButton('Continue', onPressed: _touched && !_inFuture ? _continue : null),
      ],
    );
  }
}

/// Under 21: a calm, final notice. No back button — retrying isn't a path.
class _Blocked extends StatelessWidget {
  const _Blocked();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: CarinoColors.canvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(CarinoSpace.margin),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${AppConfig.appName} is ${AppConfig.minimumAge}+ only', style: CarinoText.display),
                  const SizedBox(height: CarinoSpace.lg),
                  Text(
                    'Thanks for your honesty. This isn’t a “try again with a different date” thing. '
                    'We’ll be here when you’re ${AppConfig.minimumAge}.',
                    style: CarinoText.lead,
                  ),
                ]),
          ),
        ),
      );
}
