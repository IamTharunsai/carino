import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../models/message.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../discover/profile_detail_screen.dart';

/// S-038 Conversation Settings — everything about THIS conversation in one
/// place: partner (→ S-019), mode (Keep/Vanish, both-agree rule), read
/// receipts, sensitive-media blur, mute, and Block/Report. Safety rows are
/// never paywalled; receipts follow your S-047 privacy choice.
class ConversationSettingsScreen extends StatefulWidget {
  const ConversationSettingsScreen({
    super.key,
    required this.conversation,
    required this.member,
  });

  final Conversation conversation;
  final Member member;

  @override
  State<ConversationSettingsScreen> createState() =>
      _ConversationSettingsScreenState();
}

class _ConversationSettingsScreenState
    extends State<ConversationSettingsScreen> {
  final UserPrefs _prefs = Services.prefs;
  bool _muted = false;
  late final _note = TextEditingController(
      text: Services.prefs.matchNotes[widget.member.id] ?? '');

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    final member = widget.member;
    final vanish = conv.mode == ChatMode.vanish;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Conversation settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
                backgroundImage: AssetImage(member.photoAsset)),
            title: Text('${member.name}, ${member.age}'),
            subtitle: Text('${member.intention.label} · View profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProfileDetailScreen(member: member),
              ),
            ),
          ),
          // Things to remember: private, own-row only.
          TextField(
            controller: _note,
            maxLength: 300,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Things to remember (only you see this)',
              hintText: 'Dog called Biscuit · loves the café on High St',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              Services.prefs.matchNotes[member.id] = v.trim();
              Services.prefs.save();
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(vanish ? Icons.timer_outlined : Icons.lock_outline),
            title: const Text('Message mode'),
            subtitle: Text(vanish
                ? 'Vanish · dissolves ${conv.vanishMinutes == 0 ? 'after reading' : '${conv.vanishMinutes} min after reading'}'
                : 'Keep · messages stay'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Mode changes need BOTH people (S-036B). Scaffold: flips
              // locally with the rule stated; production sends a proposal
              // and flips only on accept — prospective only either way.
              setState(() {
                conv.mode = vanish ? ChatMode.keep : ChatMode.vanish;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Mode change proposed to ${member.firstName} — it applies to new messages only when both agree (demo: applied).'),
                ),
              );
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Read receipts'),
            subtitle: const Text('Let them see when you\'ve read messages.'),
            value: _prefs.readReceipts,
            onChanged: (v) => setState(() => _prefs.readReceipts = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Blur sensitive media'),
            subtitle: const Text(
                'Photos/videos start blurred until you tap them.'),
            value: _prefs.sensitiveMediaBlur,
            onChanged: (v) => setState(() => _prefs.sensitiveMediaBlur = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mute notifications'),
            subtitle: const Text('For this conversation only.'),
            value: _muted,
            onChanged: (v) => setState(() => _muted = v),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report'),
            onTap: () => SafetyActions.showReportFlow(context,
                member: member, surface: 'Chat settings'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.block, color: Color(0xFFB81735)),
            title: const Text('Block'),
            onTap: () => SafetyActions.showBlockConfirmation(context,
                member: member),
          ),
        ],
      ),
    );
  }
}
