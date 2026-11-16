/// Free vs Plus — the one place the split lives (docs/MONETIZATION-STRATEGY.md).
/// Safety (verify, report, block, check-ins, incognito) is never in here.
library;

const freeLikesPerDay = 10;
const freeSparksPerDay = 1;
const plusSparksPerDay = 5;
const superLikePackSize = 5;

/// Display prices for the US launch. The store sheet shows the final,
/// localised price before anyone confirms.
const plusMonthlyPrice = r'$12.99';
const plusAnnualPrice = r'$89.99';
const superLikePackPrice = r'$4.99';

typedef PlanRow = ({String label, String free, String plus});

const List<PlanRow> planRows = [
  (label: 'Verified discovery, Daily Drop, video profiles', free: 'Included', plus: 'Included'),
  (label: 'Matching, messaging, games, Vanish chat', free: 'Included', plus: 'Included'),
  (label: 'Join plans and Decompress experiences', free: 'Included', plus: 'Included'),
  (label: 'Likes a day', free: '$freeLikesPerDay', plus: 'Unlimited'),
  (label: 'See who liked you', free: 'Count', plus: 'Everyone'),
  (label: 'Super Likes a day', free: '$freeSparksPerDay', plus: '$plusSparksPerDay'),
  (label: 'Rewind a pass', free: '—', plus: 'Included'),
  (label: 'Read receipts', free: '—', plus: 'Included'),
  (label: 'Advanced filters', free: 'Basic', plus: 'Full'),
  (label: 'Travel mode (Worldwide)', free: '—', plus: 'Included'),
  (label: 'Spark Night seats', free: 'Standard', plus: 'Priority'),
];
