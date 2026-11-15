// Notifications that feel personal and stay honest. Pure Dart, tested in
// test/notify_test.dart. Architecture: docs/NOTIFICATIONS.md.
//
// Rule zero: a notification exists ONLY because something real happened
// (a real message, match, like, plan, check-in). The words are personal —
// the member's language and tone — the facts never are invented.

enum NotifKind { match, message, likeReceived, planReminder, safetyCheckIn, streakAtRisk, momentReply, dailyDrop }

enum NotifTone { calm, playful }

class NotifEvent {
  const NotifEvent(this.kind, {this.who, this.detail});
  final NotifKind kind;

  /// The real person involved (null where it must stay hidden, e.g. likes).
  final String? who;

  /// Real context: the plan's place type, the streak day, etc.
  final String? detail;
}

class NotifPrefs {
  const NotifPrefs({
    required this.language,
    this.tone = NotifTone.calm,
    this.genericPreviews = true,
    this.off = const {},
    this.quietStart = 22,
    this.quietEnd = 8,
    this.dailyCap = 5,
  });

  final String language;
  final NotifTone tone;

  /// Lock screen shows "New message" — never a name or content.
  final bool genericPreviews;
  final Set<NotifKind> off;
  final int quietStart, quietEnd, dailyCap;
}

class Notif {
  const Notif(this.kind, this.title, this.body, this.lockScreen);
  final NotifKind kind;
  final String title;
  final String body;

  /// What shows on a locked phone.
  final String lockScreen;
}

const supportedNotifLanguages = ['English', 'Spanish', 'Hindi', 'Telugu', 'French', 'Portuguese'];

/// Messages and plans are things a person is waiting on; safety is never held.
const _uncapped = {NotifKind.message, NotifKind.planReminder, NotifKind.safetyCheckIn};

/// Null = don't send (category off, quiet hours, or today's cap reached).
Notif? compose(NotifEvent e, NotifPrefs p, {required DateTime at, required int sentToday}) {
  if (p.off.contains(e.kind) && e.kind != NotifKind.safetyCheckIn) return null;
  final quiet = p.quietStart > p.quietEnd
      ? at.hour >= p.quietStart || at.hour < p.quietEnd
      : at.hour >= p.quietStart && at.hour < p.quietEnd;
  if (quiet && e.kind != NotifKind.safetyCheckIn) return null;
  if (sentToday >= p.dailyCap && !_uncapped.contains(e.kind)) return null;

  final lang = _copy[p.language] ?? _copy['English']!;
  final playful = p.tone == NotifTone.playful && p.language == 'English';
  final (title, body) = (playful ? _playful : lang)[e.kind]!;
  String fill(String s) => s.replaceAll('{who}', e.who ?? '').replaceAll('{detail}', e.detail ?? '');
  final generic = _generic[p.language] ?? _generic['English']!;
  return Notif(
    e.kind,
    fill(title),
    fill(body),
    p.genericPreviews ? '${_appName()} · $generic' : fill(body),
  );
}

String _appName() => 'Cariño';

const _generic = {
  'English': 'Something new for you',
  'Spanish': 'Tienes algo nuevo',
  'Hindi': 'आपके लिए कुछ नया',
  'Telugu': 'మీకోసం కొత్తది',
  'French': 'Du nouveau pour vous',
  'Portuguese': 'Novidade para você',
};

// ponytail: string tables, not a localisation framework — swap for ARB files
// when there are more than a handful of languages. Native-speaker review
// required before launch for every non-English row.
const Map<NotifKind, (String, String)> _playful = {
  NotifKind.match: ("It's a spark ✨", '{who} liked you back. Say something they\'ll remember.'),
  NotifKind.message: ('New message', '{who} just wrote to you 💬'),
  NotifKind.likeReceived: ('Someone likes you', 'A verified person liked your profile. Curious?'),
  NotifKind.planReminder: ('Tomorrow: {detail} 🎉', '{detail} with {who} is tomorrow — check-in is ready.'),
  NotifKind.safetyCheckIn: ('Are you okay?', 'Your check-in for {detail} with {who} is due. Tap to confirm.'),
  NotifKind.streakAtRisk: ('Keep it going 🔥', 'Day {detail} with {who} — one game or voice note keeps it alive.'),
  NotifKind.momentReply: ('{who} replied', '{who} answered your Moment 👀'),
  NotifKind.dailyDrop: ('Your Daily Drop is here', 'A few new verified people, picked for your tastes.'),
};

const Map<String, Map<NotifKind, (String, String)>> _copy = {
  'English': {
    NotifKind.match: ("It's a match", '{who} liked you back.'),
    NotifKind.message: ('New message', '{who} sent you a message.'),
    NotifKind.likeReceived: ('New like', 'A verified person liked your profile.'),
    NotifKind.planReminder: ('Plan tomorrow', '{detail} with {who} is tomorrow.'),
    NotifKind.safetyCheckIn: ('Check-in due', 'Confirm you\'re okay after {detail} with {who}.'),
    NotifKind.streakAtRisk: ('Streak reminder', 'Day {detail} with {who}. One small thing keeps it going.'),
    NotifKind.momentReply: ('Moment reply', '{who} replied to your Moment.'),
    NotifKind.dailyDrop: ('Daily Drop', 'New verified people picked for your tastes.'),
  },
  'Spanish': {
    NotifKind.match: ('¡Hay conexión!', 'A {who} también le gustas.'),
    NotifKind.message: ('Nuevo mensaje', '{who} te envió un mensaje.'),
    NotifKind.likeReceived: ('Nuevo me gusta', 'A una persona verificada le gustó tu perfil.'),
    NotifKind.planReminder: ('Plan para mañana', '{detail} con {who} es mañana.'),
    NotifKind.safetyCheckIn: ('Confirma que estás bien', 'Confirma que estás bien después de {detail} con {who}.'),
    NotifKind.streakAtRisk: ('Tu racha', 'Día {detail} con {who}. Un pequeño gesto la mantiene.'),
    NotifKind.momentReply: ('Respuesta a tu Momento', '{who} respondió a tu Momento.'),
    NotifKind.dailyDrop: ('Tu selección diaria', 'Nuevas personas verificadas según tus gustos.'),
  },
  'Hindi': {
    NotifKind.match: ('मैच हो गया', '{who} ने भी आपको पसंद किया।'),
    NotifKind.message: ('नया संदेश', '{who} ने आपको संदेश भेजा।'),
    NotifKind.likeReceived: ('नई पसंद', 'एक सत्यापित व्यक्ति को आपकी प्रोफ़ाइल पसंद आई।'),
    NotifKind.planReminder: ('कल का प्लान', '{who} के साथ {detail} कल है।'),
    NotifKind.safetyCheckIn: ('चेक-इन करें', '{who} के साथ {detail} के बाद बताएं कि आप ठीक हैं।'),
    NotifKind.streakAtRisk: ('आपकी स्ट्रीक', '{who} के साथ दिन {detail}। एक छोटी सी बात इसे जारी रखेगी।'),
    NotifKind.momentReply: ('मोमेंट पर जवाब', '{who} ने आपके मोमेंट का जवाब दिया।'),
    NotifKind.dailyDrop: ('आज की पसंद', 'आपकी पसंद के नए सत्यापित लोग।'),
  },
  'Telugu': {
    NotifKind.match: ('మ్యాచ్ అయ్యింది', '{who} కూడా మిమ్మల్ని ఇష్టపడ్డారు.'),
    NotifKind.message: ('కొత్త సందేశం', '{who} మీకు సందేశం పంపారు.'),
    NotifKind.likeReceived: ('కొత్త లైక్', 'ధృవీకరించబడిన ఒకరు మీ ప్రొఫైల్‌ను ఇష్టపడ్డారు.'),
    NotifKind.planReminder: ('రేపటి ప్లాన్', '{who} తో {detail} రేపు ఉంది.'),
    NotifKind.safetyCheckIn: ('చెక్-ఇన్ చేయండి', '{who} తో {detail} తర్వాత మీరు క్షేమంగా ఉన్నారని తెలపండి.'),
    NotifKind.streakAtRisk: ('మీ స్ట్రీక్', '{who} తో రోజు {detail}. ఒక చిన్న పని దీన్ని కొనసాగిస్తుంది.'),
    NotifKind.momentReply: ('మూమెంట్‌కు జవాబు', '{who} మీ మూమెంట్‌కు జవాబిచ్చారు.'),
    NotifKind.dailyDrop: ('ఈరోజు ఎంపిక', 'మీ అభిరుచులకు తగిన కొత్త ధృవీకరించబడిన వ్యక్తులు.'),
  },
  'French': {
    NotifKind.match: ("C'est un match", '{who} vous a aussi liké.'),
    NotifKind.message: ('Nouveau message', '{who} vous a écrit.'),
    NotifKind.likeReceived: ('Nouveau like', 'Une personne vérifiée a aimé votre profil.'),
    NotifKind.planReminder: ('Plan demain', '{detail} avec {who}, c\'est demain.'),
    NotifKind.safetyCheckIn: ('Tout va bien ?', 'Confirmez que tout va bien après {detail} avec {who}.'),
    NotifKind.streakAtRisk: ('Votre série', 'Jour {detail} avec {who}. Un petit geste la prolonge.'),
    NotifKind.momentReply: ('Réponse à votre Moment', '{who} a répondu à votre Moment.'),
    NotifKind.dailyDrop: ('Votre sélection du jour', 'De nouvelles personnes vérifiées selon vos goûts.'),
  },
  'Portuguese': {
    NotifKind.match: ('Deu match', '{who} também curtiu você.'),
    NotifKind.message: ('Nova mensagem', '{who} enviou uma mensagem.'),
    NotifKind.likeReceived: ('Nova curtida', 'Uma pessoa verificada curtiu seu perfil.'),
    NotifKind.planReminder: ('Plano amanhã', '{detail} com {who} é amanhã.'),
    NotifKind.safetyCheckIn: ('Está tudo bem?', 'Confirme que está bem depois de {detail} com {who}.'),
    NotifKind.streakAtRisk: ('Sua sequência', 'Dia {detail} com {who}. Um pequeno gesto mantém.'),
    NotifKind.momentReply: ('Resposta ao seu Momento', '{who} respondeu ao seu Momento.'),
    NotifKind.dailyDrop: ('Sua seleção do dia', 'Novas pessoas verificadas para os seus gostos.'),
  },
};
