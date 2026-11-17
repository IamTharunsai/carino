/// Free vs Plus — the one place the split lives (docs/MONETIZATION-STRATEGY.md).
/// Safety (verify, report, block, check-ins, incognito) is never in here.
library;

const freeLikesPerDay = 10;
const freeSparksPerDay = 1;
const plusSparksPerDay = 5;
const superLikePackSize = 5;

/// Display prices for the US launch. The store sheet shows the final,
/// localised price before anyone confirms.
const plusMonthlyPrice = r'$7.99';
const plusAnnualPrice = r'$59.99';
const superLikePackPrice = r'$4.99';

typedef PlanRow = ({String label, String free, String plus});

const List<PlanRow> planRows = [
  (label: 'Unlimited Feed, hearts on posts, follows', free: 'Included', plus: 'Included'),
  (label: 'Verified discovery, Daily Drop, video profiles', free: 'Included', plus: 'Included'),
  (label: 'Matching, messaging, games, Vanish chat', free: 'Included', plus: 'Included'),
  (label: 'Join plans and Decompress experiences', free: 'Included', plus: 'Included'),
  (label: 'Hearts a day', free: '$freeLikesPerDay', plus: 'Unlimited'),
  (label: 'Gold tick (ID check) · shown first on Dates', free: 'Included', plus: 'Included'),
  (label: 'See who has a crush on you', free: 'Count', plus: 'Everyone'),
  (label: 'Crushes a day 💘', free: '$freeSparksPerDay', plus: '$plusSparksPerDay'),
  (label: 'Rewind a pass', free: 'Included', plus: 'Included'),
  (label: 'Read receipts', free: '—', plus: 'Included'),
  (label: 'Advanced filters', free: 'Basic', plus: 'Full'),
  (label: 'Travel mode (Worldwide)', free: '—', plus: 'Included'),
  (label: 'Spark Night seats', free: 'Standard', plus: 'Priority'),
  (label: 'Comment on posts', free: '—', plus: 'Included'),
  (label: 'Video posts', free: '1 min', plus: '3 min'),
  (label: 'Spark video calls', free: '15 min', plus: 'Unlimited'),
];

/// Gold-tick (ID-checked) profiles are shown first; order is otherwise kept.
List<T> goldFirst<T>(List<T> deck, {required bool Function(T) isGold}) =>
    [...deck.where(isGold), ...deck.where((m) => !isGold(m))];
