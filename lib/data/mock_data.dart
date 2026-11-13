import '../config/app_config.dart';
import '../models/member.dart';
import '../models/message.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// SAMPLE DATA — clearly-marked demo content for the scaffold.
///
/// These are NOT real users. Production data comes from BackendService
/// (Supabase) and only ever contains verified, consenting members.
/// AI honesty rule (blueprint AI FEATURES): no fake users, matches, likes
/// or messages may ever be presented as people in the live product.
/// ─────────────────────────────────────────────────────────────────────────
class MockData {
  MockData._();

  static const List<Member> members = [
    Member(
      id: 'm-aria',
      name: 'Aria',
      age: 24,
      city: 'Columbus',
      distanceBand: 'Within a few miles',
      intention: Intention.casualDating,
      photoAsset: AppConfig.assetBackdropDiscover,
      headline: 'Gallery mornings, street-food nights.',
      prompts: [
        PromptAnswer('My ideal first plan', 'Coffee, then we rate the café\'s playlist.'),
        PromptAnswer('Two truths and a lie', 'I\'ve run a 10K · I bake sourdough · I hate cilantro'),
        PromptAnswer('Green flag I look for', 'You can laugh at yourself mid-story.'),
      ],
      interests: ['Photography', 'Indie films', 'Farmers markets', 'Vinyl'],
      hasVoiceIntro: true,
      onlineNow: true,
      structure: 'Monogamy',
      pace: 'Meet after chatting',
      availability: 'Weekends',
      boundaries: 'Public places first, always. No last-minute address swaps.',
      photoAssets: [
        AppConfig.assetBackdropDiscover,
        AppConfig.assetHeroWelcome,
        AppConfig.assetBackdropMatch,
      ],
    ),
    Member(
      id: 'm-dev',
      name: 'Dev',
      age: 27,
      city: 'Columbus',
      distanceBand: 'Same neighbourhood',
      intention: Intention.longTerm,
      photoAsset: AppConfig.assetHeroWelcome,
      headline: 'Building apps by day, hunting the perfect taco by night.',
      prompts: [
        PromptAnswer('My ideal first plan', 'A walk, a bookstore, and no agenda after.'),
        PromptAnswer('Unpopular opinion', 'Breakfast food is the best dinner food.'),
        PromptAnswer('Green flag I look for', 'Kind to waiters, curious about everything.'),
      ],
      interests: ['Startups', 'Trail running', 'Cooking', 'Chess'],
    ),
    Member(
      id: 'm-sofia',
      name: 'Sofia',
      age: 23,
      city: 'Dublin',
      distanceBand: 'Within a few miles',
      intention: Intention.hangoutAndPlay,
      photoAsset: AppConfig.assetBackdropMatch,
      headline: 'Game night champion seeking a worthy rival.',
      prompts: [
        PromptAnswer('My ideal first plan', 'Arcade + loser buys milkshakes.'),
        PromptAnswer('Two truths and a lie', 'I speak 3 languages · I\'ve met a llama · I can juggle'),
        PromptAnswer('Green flag I look for', 'Competitive at trivia, chill about everything else.'),
      ],
      interests: ['Board games', 'Karaoke', 'Bouldering', 'Comedy shows'],
      languages: ['English', 'Spanish'],
      onlineNow: true,
    ),
    Member(
      id: 'm-marcus',
      name: 'Marcus',
      age: 29,
      city: 'Columbus',
      distanceBand: 'Across town',
      intention: Intention.tonight,
      photoAsset: AppConfig.assetHeroWelcome,
      headline: 'Live jazz and late-night ramen. That\'s the pitch.',
      prompts: [
        PromptAnswer('My ideal first plan', 'Jazz bar, one drink, great conversation.'),
        PromptAnswer('Unpopular opinion', 'Pineapple belongs on pizza. Fight me (gently).'),
        PromptAnswer('Green flag I look for', 'Has a favourite song and a story about it.'),
      ],
      interests: ['Jazz', 'Vinyl', 'Ramen tours', 'Photography'],
    ),
    Member(
      id: 'm-priya',
      name: 'Priya',
      age: 26,
      city: 'Columbus',
      distanceBand: 'Within a few miles',
      intention: Intention.longTerm,
      photoAsset: AppConfig.assetBackdropDiscover,
      headline: 'Doctor by day. Plant rescuer, always.',
      prompts: [
        PromptAnswer('My ideal first plan', 'Botanical gardens, then chai.'),
        PromptAnswer('Two truths and a lie', 'I\'ve fostered 12 cats · I grow chillies · I can\'t swim'),
        PromptAnswer('Green flag I look for', 'Asks follow-up questions.'),
      ],
      interests: ['Gardening', 'Classical music', 'Hiking', 'Book clubs'],
      languages: ['English', 'Hindi', 'Telugu'],
    ),
  ];

  static Member memberById(String id) =>
      members.firstWhere((m) => m.id == id, orElse: () => members.first);

  /// Today's Daily Drop — a FINITE curated set with a truthful count
  /// (blueprint S-016: no fake scarcity, ever).
  static List<Member> get dailyDrop => members.take(3).toList();

  static List<MatchConnection> get matches => [
        MatchConnection(
          id: 'match-aria',
          member: memberById('m-aria'),
          matchedAtLabel: 'Today',
          planStatus: 'Coffee suggested · awaiting their confirm',
          // Conversation + plan exist -> no expiry (see MatchConnection docs).
        ),
        MatchConnection(
          id: 'match-sofia',
          member: memberById('m-sofia'),
          matchedAtLabel: 'Yesterday',
          // Unmessaged: the real expiry clock is showing.
          expiresInLabel: 'Expires in 19h',
        ),
      ];

  /// Expired unmessaged matches land here — kept, quiet, never shamed
  /// (REA §5.1). The member can leave them archived forever.
  static List<MatchConnection> get archivedMatches => [
        MatchConnection(
          id: 'match-marcus-archived',
          member: memberById('m-marcus'),
          matchedAtLabel: 'Last week',
          archived: true,
        ),
      ];

  static List<Moment> get moments => [
        Moment(
          id: 'moment-1',
          member: memberById('m-sofia'),
          caption: 'Won game night. The crown is heavy. 👑',
          imageAsset: AppConfig.assetBackdropMatch,
          expiresInLabel: '6h left',
        ),
        Moment(
          id: 'moment-2',
          member: memberById('m-aria'),
          caption: 'Golden hour did the work, I just showed up.',
          imageAsset: AppConfig.assetBackdropDiscover,
          expiresInLabel: '11h left',
        ),
        Moment(
          id: 'moment-3',
          member: memberById('m-dev'),
          caption: 'Sunset lap around the lake. PB!',
          imageAsset: AppConfig.assetHeroWelcome,
          expiresInLabel: '2h left',
        ),
      ];

  static List<Conversation> conversations() => [
        Conversation(
          id: 'conv-aria',
          memberId: 'm-aria',
          mode: ChatMode.keep,
          unreadCount: 1,
          planPinned: true,
          messages: [
            ChatMessage(id: 'a1', text: 'Okay your café-playlist prompt got me. Defend your ranking system 😄', fromMe: false, timeLabel: '10:02'),
            ChatMessage(id: 'a2', text: 'Simple: any café playing lo-fi remixes of itself loses a star automatically.', fromMe: true, timeLabel: '10:05'),
            ChatMessage(id: 'a3', text: 'Harsh but fair. There\'s a place on High St that would pass your audit…', fromMe: false, timeLabel: '10:06'),
          ],
        ),
        Conversation(
          id: 'conv-sofia',
          memberId: 'm-sofia',
          mode: ChatMode.vanish,
          vanishMinutes: 60,
          messages: [
            ChatMessage(id: 's1', text: 'Two Truths and a Lie', fromMe: false, timeLabel: '09:41', isGameCard: true, gameTitle: 'Two Truths and a Lie', expiresInLabel: 'Vanish · 60 min after read'),
            ChatMessage(id: 's2', text: 'I guessed the llama one. I was WRONG?!', fromMe: true, timeLabel: '09:43', expiresInLabel: 'Vanish · 60 min after read'),
            ChatMessage(id: 's3', text: 'The llama is real. His name is Biscuit.', fromMe: false, timeLabel: '09:44', expiresInLabel: 'Vanish · 60 min after read'),
            // S-036 system notice: screenshots are DETECTED, never promised
            // prevented. Production renders this from a real detection
            // event (iOS userDidTakeScreenshotNotification).
            ChatMessage(id: 's4', text: 'A screenshot was detected in this conversation — Sofia was notified. Screenshots can\'t be blocked on every phone; you\'ll always be told when one is detected.', fromMe: false, timeLabel: '09:45', isSystemNotice: true),
          ],
        ),
      ];

  static const List<GameQuestion> thisOrThatDeck = [
    GameQuestion(prompt: 'Sunrise hike or sunset picnic?', options: ['Sunrise hike', 'Sunset picnic']),
    GameQuestion(prompt: 'Big night out or cozy night in?', options: ['Night out', 'Night in']),
    GameQuestion(prompt: 'Window seat or aisle seat?', options: ['Window', 'Aisle']),
    GameQuestion(prompt: 'Text first or call first?', options: ['Text', 'Call']),
    GameQuestion(prompt: 'Beach week or mountain week?', options: ['Beach', 'Mountains']),
  ];

  static const TwoTruthsRound twoTruthsRound = TwoTruthsRound(
    statements: [
      'I\'ve run a full marathon',
      'I once cooked for 40 people',
      'I\'ve never seen snow',
    ],
    lieIndex: 2,
  );

  static const List<PlanSuggestion> planIdeas = [
    PlanSuggestion(id: 'p1', placeType: 'Coffee', timeLabel: 'Sat · 11:00', note: 'Low-key, public, easy exit — the classic first plan.'),
    PlanSuggestion(id: 'p2', placeType: 'Gallery walk', timeLabel: 'Sun · 14:00', note: 'Built-in conversation: the art does half the talking.'),
    PlanSuggestion(id: 'p3', placeType: 'Street-food market', timeLabel: 'Fri · 18:30', note: 'Graze, compare notes, crown a winner stall.'),
  ];

  /// S-021 Likes You — the count is REAL (these are the people); free sees
  /// the count + blurred teaser, Plus reveals the rows.
  static List<Member> get likesYou => [
        memberById('m-priya'),
        memberById('m-marcus'),
      ];

  /// S-041 Plans — upcoming + past, with honest states.
  static const List<MockPlan> plans = [
    MockPlan(
      id: 'plan-1',
      memberId: 'm-aria',
      placeType: 'Coffee',
      timeLabel: 'Sat · 11:00',
      state: 'Confirmed — you both said yes',
      upcoming: true,
    ),
    MockPlan(
      id: 'plan-2',
      memberId: 'm-sofia',
      placeType: 'Street-food market',
      timeLabel: 'Last Fri · 18:30',
      state: 'Happened',
      upcoming: false,
      feedbackPending: true,
    ),
  ];

  /// S-056 Notifications Centre — every item maps to a REAL event.
  static const List<MockNotification> notifications = [
    MockNotification(
      id: 'n1',
      category: 'Matches',
      text: 'You and Sofia liked each other',
      timeLabel: 'Yesterday',
      target: 'connect',
    ),
    MockNotification(
      id: 'n2',
      category: 'Messages',
      text: 'Aria sent you a message',
      timeLabel: '10:06',
      target: 'chats',
    ),
    MockNotification(
      id: 'n3',
      category: 'Plans',
      text: 'Coffee with Aria — Sat 11:00, confirmed by both',
      timeLabel: '09:15',
      target: 'plans',
    ),
  ];

  /// The signed-in demo user ("You"). Sample profile for the scaffold.
  static const Member currentUser = Member(
    id: 'me',
    name: 'You',
    age: 25,
    city: 'Columbus',
    distanceBand: '—',
    intention: Intention.casualDating,
    photoAsset: AppConfig.assetHeroWelcome,
    headline: 'Here for good conversation and better plans.',
    prompts: [
      PromptAnswer('My ideal first plan', 'Coffee and a walk — simple beats fancy.'),
    ],
    interests: ['Tech', 'Coffee', 'Live music'],
  );
}

/// A plan row for S-041 (display model over the Plan entity).
class MockPlan {
  const MockPlan({
    required this.id,
    required this.memberId,
    required this.placeType,
    required this.timeLabel,
    required this.state,
    required this.upcoming,
    this.feedbackPending = false,
  });

  final String id;
  final String memberId;
  final String placeType;
  final String timeLabel;
  final String state;
  final bool upcoming;
  final bool feedbackPending;
}

/// A notification row for S-056. [target] = which surface the deep link
/// opens ('connect' | 'chats' | 'plans').
class MockNotification {
  const MockNotification({
    required this.id,
    required this.category,
    required this.text,
    required this.timeLabel,
    required this.target,
  });

  final String id;
  final String category;
  final String text;
  final String timeLabel;
  final String target;
}
