import '../config/app_config.dart';
import '../models/experience.dart';
import '../models/member.dart';
import '../models/message.dart';
import '../models/platform.dart';
import '../models/social.dart';
import '../models/sync.dart';
import '../models/wellbeing.dart';

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
      gender: ['Woman'],
      pronouns: 'she/her',
      orientation: 'Bisexual',
      identityVisibility: {'orientation': 'matches'},
      wantToMeet: ['Men', 'Women', 'Non-binary people'],
      anthem: 'Golden Hour · JVKE',
      topArtists: ['SZA', 'Khruangbin', 'Mitski'],
      tasteAnswers: {'t1': 'Slow brunch', 't2': 'Midnight pancakes', 't3': 'Coffee and a walk', 't6': 'Voice notes'},
      textingStyle: TextingStyle(pace: ReplyPace.evenings, length: MsgLength.long, voice: VoiceNotes.love, humour: Humour.playful, loves: ['Film photography', 'Café playlists'], avoid: ['Exes']),
      comfort: ComfortRules(photosAfterDays: 3, daytimeFirstMeet: true),
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
      gender: ['Man'],
      pronouns: 'he/him',
      orientation: 'Straight',
      wantToMeet: ['Women'],
      topArtists: ['Bon Iver', 'Kendrick Lamar'],
      tasteAnswers: {'t1': 'Sunrise hike', 't3': 'Something active', 't5': 'Planned to the minute'},
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
      gender: ['Woman'],
      pronouns: 'she/they',
      orientation: 'Queer',
      wantToMeet: ['Women', 'Non-binary people', 'Men'],
      anthem: 'Dancing Queen · ABBA',
      topArtists: ['ABBA', 'Charli XCX'],
      tasteAnswers: {'t2': 'Midnight pancakes', 't4': 'Aux cord, always', 't8': 'Big group energy'},
      textingStyle: TextingStyle(pace: ReplyPace.quick, length: MsgLength.short, voice: VoiceNotes.textOnly, humour: Humour.dry, loves: ['Karaoke picks', 'Climbing'], avoid: ['Work talk']),
      comfort: ComfortRules(noCallsBeforeMeet: true),
      highlights: ['Won game night. The crown is heavy. 👑', 'Karaoke PB: 94 points'],
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
      gender: ['Man'],
      pronouns: 'he/him',
      orientation: 'Gay',
      wantToMeet: ['Men'],
      anthem: 'So What · Miles Davis',
      tasteAnswers: {'t2': 'Midnight pancakes', 't4': 'Aux cord, always'},
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
      gender: ['Woman'],
      pronouns: 'she/her',
      orientation: 'Straight',
      identityVisibility: {'orientation': 'hidden'},
      wantToMeet: ['Men'],
      tasteAnswers: {'t1': 'Sunrise hike', 't3': 'Coffee and a walk', 't7': 'Farmers market'},
      comfort: ComfortRules(opensFirst: true),
    ),
    Member(
      id: 'm-rowan',
      name: 'Rowan',
      age: 31,
      city: 'Columbus',
      distanceBand: 'Within a few miles',
      intention: Intention.longTerm,
      photoAsset: AppConfig.assetBackdropMatch,
      headline: 'Ceramics on Sundays, terrible puns all week.',
      prompts: [
        PromptAnswer('My ideal first plan', 'Pottery class — we both make something lopsided.'),
        PromptAnswer('I communicate best by', 'Saying things plainly. Ask me anything directly.'),
        PromptAnswer('Green flag I look for', 'Uses the right pronouns without making it a thing.'),
      ],
      interests: ['Ceramics', 'Board games', 'Live music', 'Coffee'],
      structure: 'Figuring it out',
      gender: ['Non-binary'],
      pronouns: 'they/them',
      orientation: 'Queer',
      wantToMeet: ['Women', 'Men', 'Non-binary people'],
      anthem: 'Motion Sickness · Phoebe Bridgers',
      tasteAnswers: {'t1': 'Slow brunch', 't6': 'Voice notes', 't7': 'Couch + a series', 't8': 'Just us'},
      accessNote: 'Quiet venues help me — loud bars are a no.',
    ),
    Member(
      id: 'm-elena',
      name: 'Elena',
      age: 44,
      city: 'Columbus',
      distanceBand: 'Across town',
      intention: Intention.longTerm,
      photoAsset: AppConfig.assetHeroWelcome,
      headline: 'Single mum of one, fluent in sarcasm and Italian.',
      prompts: [
        PromptAnswer('My ideal first plan', 'Wine bar, early evening — I have a sitter till 10.'),
        PromptAnswer('Non-negotiable', 'Kindness. And you must like dogs.'),
        PromptAnswer('Green flag I look for', 'Makes plans and keeps them.'),
      ],
      interests: ['Cooking', 'Dogs', 'Travel', 'Book clubs'],
      languages: ['English', 'Italian'],
      availability: 'Weekends',
      pace: 'Meet soon',
      gender: ['Woman'],
      pronouns: 'she/her',
      orientation: 'Straight',
      wantToMeet: ['Men'],
      tasteAnswers: {'t3': 'Coffee and a walk', 't5': 'Planned to the minute', 't7': 'Farmers market'},
      accessNote: 'Step-free venues, please — bad knee from skiing.',
    ),
  ];


  // ── Social (Phase 1) ── sample friends, groups and friend Moments. ──────
  // Friends are people, not dating profiles: they never appear in Dates.

  static const List<Member> friends = [
    Member(
      id: 'f-maya', name: 'Maya', age: 26, city: 'Columbus',
      distanceBand: '—', intention: Intention.stillExploring,
      photoAsset: AppConfig.assetBackdropDiscover,
      headline: 'Best friend since year 7.', prompts: [], interests: [],
    ),
    Member(
      id: 'f-jordan', name: 'Jordan', age: 27, city: 'Columbus',
      distanceBand: '—', intention: Intention.stillExploring,
      photoAsset: AppConfig.assetHeroWelcome,
      headline: 'Run club captain.', prompts: [], interests: [],
    ),
    Member(
      id: 'f-sam', name: 'Sam', age: 25, city: 'Columbus',
      distanceBand: '—', intention: Intention.stillExploring,
      photoAsset: AppConfig.assetBackdropMatch,
      headline: 'Always has the aux.', prompts: [], interests: [],
      pronouns: 'they/them',
    ),
    Member(
      id: 'f-nina', name: 'Nina', age: 52, city: 'Dublin',
      distanceBand: '—', intention: Intention.stillExploring,
      photoAsset: AppConfig.assetHeroWelcome,
      headline: 'Mum. Sends the best voice notes.', prompts: [], interests: [],
    ),
  ];

  /// Which circle each person is in (your private placement).
  static Map<String, Circle> get initialCircles => {
        'f-maya': Circle.inner,
        'f-nina': Circle.inner,
        'f-jordan': Circle.friends,
        'f-sam': Circle.friends,
        'm-aria': Circle.dates,
        'm-sofia': Circle.dates,
      };


  // ── Platform (Stage, Trust, Plans engine, Professional, Money) ─────────

  static const List<FeedItem> feed = [
    FeedItem(id: 'v1', creatorId: 'f-jordan', creatorName: 'Jordan', caption: 'Sunrise 5K with the club — come next week', topic: 'Fitness', minutesAgo: 40, imageAsset: AppConfig.assetHeroWelcome, fromCircle: true, planIdea: 'Run club 5K'),
    FeedItem(id: 'v2', creatorId: 'c-taco', creatorName: 'Taco Atlas', caption: 'Ranking every taco truck on Parsons Ave (part 3)', topic: 'Food', minutesAgo: 90, imageAsset: AppConfig.assetBackdropDiscover, viral: true, planIdea: 'Taco truck crawl'),
    FeedItem(id: 'v3', creatorId: 'c-dreamlab', creatorName: 'DreamLab', caption: 'A city that doesn\'t exist, made with AI', topic: 'Art', minutesAgo: 30, imageAsset: AppConfig.assetBackdropMatch, aiGenerated: true, verifiedHuman: false, viral: true),
    FeedItem(id: 'v4', creatorId: 'f-sam', creatorName: 'Sam', caption: 'Tiny gig in a record shop. Unreal.', topic: 'Music', minutesAgo: 120, imageAsset: AppConfig.assetBackdropMatch, fromCircle: true, planIdea: 'Record shop gig'),
    FeedItem(id: 'v5', creatorId: 'c-fitfuel', creatorName: 'FitFuel', caption: '1,000-calorie day: what I eat', topic: 'Diet', minutesAgo: 60, imageAsset: AppConfig.assetHeroWelcome, viral: true),
    FeedItem(id: 'v6', creatorId: 'c-clay', creatorName: 'Clay & Coffee', caption: 'Wheel-throwing for total beginners', topic: 'Art', minutesAgo: 200, imageAsset: AppConfig.assetBackdropDiscover, planIdea: 'Pottery drop-in'),
    FeedItem(id: 'v7', creatorId: 'c-jazzcbus', creatorName: 'Jazz Columbus', caption: 'Friday trio — first set is free', topic: 'Music', minutesAgo: 300, imageAsset: AppConfig.assetBackdropMatch, planIdea: 'Jazz bar'),
    FeedItem(id: 'v8', creatorId: 'c-botcomedy', creatorName: 'AutoLaughs', caption: 'AI writes stand-up (it\'s bad)', topic: 'Comedy', minutesAgo: 15, imageAsset: AppConfig.assetHeroWelcome, aiGenerated: true, verifiedHuman: false),
  ];

  static const Set<String> feedTopics = {'Fitness', 'Food', 'Art', 'Music', 'Diet', 'Comedy'};

  static const List<Gift> gifts = [
    Gift('g1', '☕', 'Coffee', 'Store price'),
    Gift('g2', '🌹', 'Rose', 'Store price'),
    Gift('g3', '🎟️', 'Gig ticket', 'Store price'),
  ];

  /// Trust Graph seed: you've met Maya and Jordan in person. Maya has met
  /// Rowan; Jordan has met Elena — so warm intros are possible to both.
  static TrustGraph initialTrust() => TrustGraph(
        met: {'f-maya', 'f-jordan'},
        metBy: {
          'f-maya': {'m-rowan', 'f-sam'},
          'f-jordan': {'m-elena', 'p-lee'},
        },
      );

  static const Map<String, bool> freeTonight = {
    'f-maya': true,
    'f-sam': true,
    'f-jordan': false,
  };

  static const List<(String, String, String)> nightIdeas = [
    ('Night market + dumplings', 't2', 'Midnight pancakes'),
    ('Board-game café', 't8', 'Big group energy'),
    ('Jazz bar, first set', 't4', 'Aux cord, always'),
  ];

  // Professional wing ------------------------------------------------------
  static const WorkFacet myWork = WorkFacet(
    personId: 'me',
    role: 'Product engineer',
    building: 'A dating app that ends in real plans',
    skills: ['Flutter', 'Product', 'Design'],
    openTo: {'coffee', 'collabs'},
  );

  static const List<WorkFacet> workFacets = [
    WorkFacet(personId: 'p-lee', role: 'Founder, climate startup', building: 'Batteries for e-bikes', skills: ['Hardware', 'Fundraising'], openTo: {'coffee', 'hiring'}),
    WorkFacet(personId: 'p-ana', role: 'Designer', building: 'An accessibility toolkit', skills: ['Design', 'Flutter'], openTo: {'coffee', 'collabs', 'mentoring'}),
    WorkFacet(personId: 'f-jordan', role: 'Physio', building: 'A running clinic', skills: ['Health'], openTo: {'mentoring'}),
  ];

  static const List<Member> professionals = [
    Member(id: 'p-lee', name: 'Lee', age: 34, city: 'Columbus', distanceBand: '—', intention: Intention.stillExploring, photoAsset: AppConfig.assetHeroWelcome, headline: 'Founder, climate startup', prompts: [], interests: []),
    Member(id: 'p-ana', name: 'Ana', age: 29, city: 'Columbus', distanceBand: '—', intention: Intention.stillExploring, photoAsset: AppConfig.assetBackdropDiscover, headline: 'Designer', prompts: [], interests: [], pronouns: 'she/her'),
  ];

  static const List<Guild> guilds = [
    Guild(id: 'gd-ai', name: 'AI Builders', blurb: 'People shipping AI products in Columbus.', memberCount: 412, rooms: ['Show & tell', 'Hiring', 'Demo nights']),
    Guild(id: 'gd-salsa', name: 'Salsa Dancers', blurb: 'Beginner-friendly socials every week.', memberCount: 238, rooms: ['Socials', 'Lessons'], datingOptIn: true),
    Guild(id: 'gd-startup', name: 'Startup People', blurb: 'Founders, operators and the curious.', memberCount: 657, rooms: ['Founders', 'Coffee chats', 'Events']),
    Guild(id: 'gd-run', name: 'Run Club', blurb: '5Ks, long runs, and brunch after.', memberCount: 189, rooms: ['Weekend runs', 'Races'], datingOptIn: true),
  ];

  /// Tonight Near Me: plans, events and open tables this evening.
  static const List<(String, String, String, int)> tonight = [
    ('Open table', 'Dumplings at the night market', '19:30 · Street market', 2),
    ('Event', 'Comedy open mic', '21:00 · Comedy club', 0),
    ('Hosted plan', 'Pickup basketball', '18:30 · Park courts', 3),
    ('Open table', 'Board-game café, 4 seats left', '20:00 · Café', 4),
  ];

  static Member personById(String id) => [...friends, ...members, ...professionals].firstWhere(
      (m) => m.id == id,
      orElse: () => members.first);

  static List<GroupChat> groups() => [
        GroupChat(
          id: 'g-weekend',
          name: 'Weekend crew',
          memberIds: ['f-maya', 'f-jordan', 'f-sam'],
          unreadCount: 2,
          messages: [
            GroupMessage(senderId: 'f-jordan', text: 'We need to actually do something this weekend', timeLabel: '18:02'),
            GroupMessage(senderId: 'f-sam', text: 'Saturday works for me, Sunday too', timeLabel: '18:04'),
            GroupMessage(senderId: 'f-maya', text: 'Bowling? Or that night market', timeLabel: '18:05'),
          ],
        ),
        GroupChat(
          id: 'g-family',
          name: 'Family 💛',
          memberIds: ['f-nina', 'f-maya'],
          messages: [
            GroupMessage(senderId: 'f-nina', text: 'Sunday lunch at mine? I\'m making the lasagne', timeLabel: 'Yesterday'),
          ],
        ),
      ];

  static List<Moment> get friendMoments => [
        Moment(
          id: 'fm-1',
          member: friends[0],
          caption: 'New haircut, who dis ✂️',
          imageAsset: AppConfig.assetBackdropDiscover,
          expiresInLabel: '9h left',
          circle: Circle.inner,
        ),
        Moment(
          id: 'fm-2',
          member: friends[1],
          caption: 'Run club 5K done. Next Saturday, who\'s in?',
          imageAsset: AppConfig.assetHeroWelcome,
          expiresInLabel: '15h left',
          circle: Circle.friends,
          sticker: const MomentSticker(
            kind: StickerKind.poll,
            question: 'Join next week?',
            options: ['I\'m in', 'Next time'],
          ),
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
          sticker: const MomentSticker(
            kind: StickerKind.poll,
            question: 'Next game night?',
            options: ['Codenames', 'Mario Kart'],
          ),
        ),
        Moment(
          id: 'moment-2',
          member: memberById('m-aria'),
          caption: 'Golden hour did the work, I just showed up.',
          imageAsset: AppConfig.assetBackdropDiscover,
          expiresInLabel: '11h left',
          sticker: const MomentSticker(
            kind: StickerKind.askMe,
            question: 'Best café in Columbus? Go.',
          ),
        ),
        Moment(
          id: 'moment-3',
          member: memberById('m-dev'),
          caption: 'Sunset lap around the lake. PB!',
          imageAsset: AppConfig.assetHeroWelcome,
          expiresInLabel: '2h left',
        ),
      ];

  /// The session's chats. ONE list, so what you send stays when you leave
  /// and come back. ponytail: in-memory demo store; live = messages table.
  static List<Conversation> conversations() => _chats;

  /// The chat with [m], created on a new match.
  static Conversation chatWith(Member m) {
    for (final c in _chats) {
      if (c.memberId == m.id) return c;
    }
    final c = Conversation(id: 'conv-${m.id}', memberId: m.id, mode: ChatMode.keep, messages: []);
    _chats.insert(0, c);
    return c;
  }

  static final List<Conversation> _chats = [
        Conversation(
          id: 'conv-aria',
          memberId: 'm-aria',
          mode: ChatMode.keep,
          unreadCount: 1,
          planPinned: true,
          daysChatting: 2,
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
          quietDays: 6,
          daysChatting: 9,
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

  /// Events Near You — public venue types, sample listings (production:
  /// partner venues + a curated city feed, server-side).
  static const List<LocalEvent> events = [
    LocalEvent(id: 'e1', title: 'Friday Night Jazz Trio', venueType: 'Jazz bar', timeLabel: 'Fri · 20:00', category: 'Music', goingMatchIds: ['m-aria']),
    LocalEvent(id: 'e2', title: 'Short North Night Market', venueType: 'Street market', timeLabel: 'Sat · 18:00', category: 'Food', stepFree: true),
    LocalEvent(id: 'e3', title: 'Beginner Pottery Drop-in', venueType: 'Ceramics studio', timeLabel: 'Sun · 14:00', category: 'Make', stepFree: true),
    LocalEvent(id: 'e4', title: 'Comedy Open Mic', venueType: 'Comedy club', timeLabel: 'Thu · 21:00', category: 'Comedy', goingMatchIds: ['m-sofia']),
    LocalEvent(id: 'e5', title: 'Riverside Run Club 5K', venueType: 'Park', timeLabel: 'Sat · 08:30', category: 'Active', stepFree: true),
  ];

  /// Speed Spark Nights — themed, scheduled, mutual-accept Spark rounds.
  static const List<SparkNight> sparkNights = [
    SparkNight(id: 'sn1', theme: 'Foodies Thursday', timeLabel: 'Thu · 19:30', blurb: 'Three 5-minute Sparks with people who love a good taco truck.'),
    SparkNight(id: 'sn2', theme: 'Over-35 Sunday', timeLabel: 'Sun · 19:00', blurb: 'Grown-up pace, same rules: full profiles, both accept.', ageBand: '35+'),
    SparkNight(id: 'sn3', theme: 'Queer Spark Night', timeLabel: 'Wed · 20:00', blurb: 'LGBTQ+ members meeting LGBTQ+ members. Hosted and moderated.'),
    SparkNight(id: 'sn4', theme: 'Gamers & Geeks', timeLabel: 'Fri · 21:00', blurb: 'Start with a round of This or That, end with a rematch.'),
  ];

  /// Decompress shelf — SAMPLE listings from imagined local partners.
  /// Production: partner inventory via booking integrations.
  static const List<Experience> decompress = [
    Experience(id: 'd1', title: 'Sunset walk on the Scioto Mile', category: 'Walk', venueType: 'Riverfront park', partner: 'Columbus Walks', timeLabel: 'Today · 18:30', durationMin: 60, priceCents: 0, spotsLeft: 6, maxPeople: 6, groupGoing: 4, stepFree: true, phoneFree: true),
    Experience(id: 'd2', title: 'Kayak the Olentangy', category: 'Water', venueType: 'River outfitter', partner: 'Olentangy Paddle Co.', timeLabel: 'Sat · 10:00', durationMin: 120, priceCents: 4500, spotsLeft: 4, maxPeople: 4, groupGoing: 2),
    Experience(id: 'd3', title: 'Beginner pottery wheel', category: 'Make', venueType: 'Ceramics studio', partner: 'Clay & Coffee', timeLabel: 'Sun · 14:00', durationMin: 90, priceCents: 3800, spotsLeft: 3, maxPeople: 2, groupGoing: 0, stepFree: true, phoneFree: true),
    Experience(id: 'd4', title: 'Park yoga, all levels', category: 'Calm', venueType: 'Park lawn', partner: 'Goodale Yoga', timeLabel: 'Sat · 09:00', durationMin: 60, priceCents: 1200, spotsLeft: 10, maxPeople: 4, groupGoing: 7, stepFree: true, phoneFree: true),
    Experience(id: 'd5', title: 'Hiking crew: Highbanks trail', category: 'Move', venueType: 'Metro park', partner: 'Trail Friends CBUS', timeLabel: 'Sun · 08:30', durationMin: 150, priceCents: 0, spotsLeft: 5, maxPeople: 5, groupGoing: 6),
    Experience(id: 'd6', title: 'Spa hour: sauna + cold plunge', category: 'Spa', venueType: 'Day spa', partner: 'Nordic Heat Studio', timeLabel: 'Fri · 19:00', durationMin: 60, priceCents: 5500, spotsLeft: 2, maxPeople: 2, groupGoing: 0),
    Experience(id: 'd7', title: 'Phone-free café hour', category: 'Café', venueType: 'Café', partner: 'Quiet Cup', timeLabel: 'Tomorrow · 16:00', durationMin: 60, priceCents: 0, spotsLeft: 8, maxPeople: 4, groupGoing: 3, stepFree: true, phoneFree: true),
    Experience(id: 'd8', title: 'Pickup volleyball', category: 'Sports', venueType: 'Sand courts', partner: 'CBUS Pickup', timeLabel: 'Thu · 18:00', durationMin: 90, priceCents: 500, spotsLeft: 4, maxPeople: 4, groupGoing: 8),
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
    gender: ['Man'],
    pronouns: 'he/him',
    // Open to everyone by default; About You narrows it.
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
