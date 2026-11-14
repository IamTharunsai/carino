import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/services.dart';
import 'home_shell.dart';
import 'onboarding/age_gate_screen.dart';
import 'onboarding/auth_screen.dart';
import 'onboarding/identity_screen.dart';
import 'onboarding/intentions_screen.dart';
import 'onboarding/permission_primers_screen.dart';
import 'onboarding/privacy_setup_screen.dart';
import 'onboarding/profile_creation_screen.dart';
import 'onboarding/taste_quiz_screen.dart';
import 'onboarding/verification_flow_screen.dart';
import 'onboarding/verification_intro_screen.dart';
import 'onboarding/waitlist_screen.dart';
import 'onboarding/welcome_screen.dart';

/// The first-run flow (blueprint NAV & IA): a linear onboarding stack with
/// NO tab bar. Under-21 or unverified states can never reach HomeShell —
/// the only doors in are the final step of this flow or a returning
/// verified session (AuthService).
enum _Stage {
  welcome,
  ageGate,
  auth,
  verificationIntro,
  verificationProvider,
  verificationResult,
  intentions,
  identity,
  tasteQuiz,
  privacySetup,
  waitlist,
  profile,
  primers,
  home,
}

class RootFlow extends StatefulWidget {
  const RootFlow({super.key});

  @override
  State<RootFlow> createState() => _RootFlowState();
}

class _RootFlowState extends State<RootFlow> {
  _Stage _stage = _Stage.welcome;
  bool _completedOnboarding = false;

  @override
  void initState() {
    super.initState();
    AuthService.sessionChanges.addListener(_onSessionChange);
  }

  @override
  void dispose() {
    AuthService.sessionChanges.removeListener(_onSessionChange);
    super.dispose();
  }

  void _onSessionChange() {
    // A sign-out anywhere invalidates the completed-onboarding shortcut.
    if (!AuthService.sessionChanges.value && mounted) {
      setState(() => _completedOnboarding = false);
    }
  }

  void _go(_Stage stage) => setState(() => _stage = stage);

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.welcome:
        return WelcomeScreen(
          onContinue: () => _go(_Stage.ageGate),
          // Returning member: PRODUCTION routes through Auth + a server
          // check that the account is verified and not restricted. The
          // scaffold honours an existing demo session; otherwise it still
          // requires the full gate chain.
          onSignIn: () => _go(
              Services.auth.isSignedIn ? _Stage.home : _Stage.auth),
        );
      case _Stage.ageGate:
        return AgeGateScreen(onPassed: () => _go(_Stage.auth));
      case _Stage.auth:
        return AuthScreen(
            onAuthenticated: () => _go(_Stage.verificationIntro));
      case _Stage.verificationIntro:
        return VerificationIntroScreen(
          onStart: () => _go(_Stage.verificationProvider),
          onExit: () => _go(_Stage.welcome),
        );
      case _Stage.verificationProvider:
        return VerificationProviderScreen(
          onComplete: () => _go(_Stage.verificationResult),
          onCancel: () => _go(_Stage.verificationIntro),
        );
      case _Stage.verificationResult:
        return VerificationResultScreen(
          onPassed: () => _go(
            Services.remoteConfig.cityBatchFull
                ? _Stage.waitlist
                : _Stage.intentions,
          ),
          onRetry: () => _go(_Stage.verificationProvider),
        );
      case _Stage.intentions:
        return IntentionsScreen(onDone: (_) => _go(_Stage.identity));
      case _Stage.identity:
        return IdentityScreen(onDone: () => _go(_Stage.tasteQuiz));
      case _Stage.tasteQuiz:
        return TasteQuizScreen(onDone: () => _go(_Stage.privacySetup));
      case _Stage.privacySetup:
        return PrivacySetupScreen(onDone: () => _go(_Stage.profile));
      case _Stage.waitlist:
        return WaitlistScreen(onAdmitted: () => _go(_Stage.intentions));
      case _Stage.profile:
        return ProfileCreationScreen(onPublished: () => _go(_Stage.primers));
      case _Stage.primers:
        return PermissionPrimersScreen(onDone: () {
          _completedOnboarding = true;
          _go(_Stage.home);
        });
      case _Stage.home:
        // Session gate: signing out anywhere (S-050) drops the app back to
        // Welcome — an unauthenticated state can never sit inside Home.
        return ValueListenableBuilder<bool>(
          valueListenable: AuthService.sessionChanges,
          builder: (context, signedIn, _) => (signedIn ||
                  Services.auth.isSignedIn ||
                  // The onboarding chain itself ends here (OTP/passkey set
                  // the gate); a completed chain is a session by definition.
                  _completedOnboarding)
              ? const HomeShell()
              : WelcomeScreen(
                  onContinue: () => _go(_Stage.ageGate),
                  onSignIn: () => _go(_Stage.auth),
                ),
        );
    }
  }
}
