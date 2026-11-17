import 'package:flutter/material.dart';
import '../config/env.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../services/services.dart';
import 'home_shell.dart';
import 'onboarding/age_gate_screen.dart';
import 'onboarding/auth_screen.dart';
import 'onboarding/profile_creation_screen.dart';
import 'onboarding/sign_in_screen.dart';
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
  signIn,
  auth,
  verificationIntro,
  verificationProvider,
  verificationResult,
  waitlist,
  faceCheck,
  profile,
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

  /// Steps visited, for the back button on every onboarding page.
  final List<_Stage> _history = [];

  /// Came in through "I already have an account": a code sign-in should
  /// land on Home, not restart verification.
  bool _returning = false;

  @override
  void initState() {
    super.initState();
    AuthService.sessionChanges.addListener(_onSessionChange);
    // A saved session opens straight into the app; Face ID / fingerprint
    // (Settings → App lock) guards it instead of a sign-in screen.
    if (Services.auth.isSignedIn || (Env.useMockBackend && Services.prefs.mockSignedIn)) {
      _returning = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!Services.auth.isSignedIn) await Services.auth.signInDemo();
        if (mounted) _afterSignIn();
      });
    }
  }

  @override
  void dispose() {
    AuthService.sessionChanges.removeListener(_onSessionChange);
    super.dispose();
  }

  /// The ONE place a signed-in member is routed: verified accounts go Home;
  /// anything else must pass the age gate + ID verification first. Every
  /// sign-in path (password, code, Google/Apple, passkey) calls this.
  Future<void> _afterSignIn() async {
    // Verification is optional (gold tick on your profile), so a signed-in
    // member goes straight in — or to their profile if it's still empty.
    if (!mounted) return;
    if (Services.prefs.photos.isEmpty && !_returning) {
      _go(_Stage.profile);
    } else {
      _completedOnboarding = true;
      _go(_Stage.home);
    }
  }

  void _onSessionChange() {
    if (Env.useMockBackend) {
      Services.prefs.mockSignedIn = AuthService.sessionChanges.value;
      Services.prefs.save();
    }
    // OAuth (Google/Apple) completes in the browser and returns via deep
    // link; the session arriving is the signal to route.
    if (AuthService.sessionChanges.value &&
        _returning &&
        (_stage == _Stage.signIn || _stage == _Stage.auth) &&
        mounted) {
      _afterSignIn();
      return;
    }
    // A sign-out anywhere invalidates the completed-onboarding shortcut.
    if (!AuthService.sessionChanges.value && mounted) {
      setState(() => _completedOnboarding = false);
    }
  }

  void _go(_Stage stage) => setState(() {
        if (stage == _Stage.home || stage == _Stage.welcome) {
          _history.clear();
        } else {
          _history.add(_stage);
        }
        _stage = stage;
      });

  void _back() {
    if (_history.isEmpty) return;
    setState(() => _stage = _history.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final page = _page();
    if (_history.isEmpty || _stage == _Stage.home) return page;
    // Every onboarding page: on-screen back (via GlassScaffold) + the
    // Android system back gesture go one step back.
    return OnboardingBack(
      onBack: _back,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: page,
      ),
    );
  }

  Widget _page() {
    switch (_stage) {
      case _Stage.welcome:
        return WelcomeScreen(
          onContinue: () => _go(_Stage.ageGate),
          // Returning member: PRODUCTION routes through Auth + a server
          // check that the account is verified and not restricted. The
          // scaffold honours an existing demo session; otherwise it still
          // requires the full gate chain.
          onSignIn: () {
            _returning = true;
            // An existing session still goes through the verified check.
            if (Services.auth.isSignedIn) {
              _afterSignIn();
            } else {
              _go(_Stage.signIn);
            }
          },
        );
      case _Stage.signIn:
        return SignInScreen(
          onSignedIn: _afterSignIn,
          onUseCode: () => _go(_Stage.auth),
        );
      case _Stage.ageGate:
        return AgeGateScreen(onPassed: () {
          _returning = false;
          // Already signed in (returning but unverified)? Straight to
          // verification — don't ask for a code twice.
          _go(Services.auth.isSignedIn ? _Stage.faceCheck : _Stage.auth);
        });
      case _Stage.auth:
        return AuthScreen(onAuthenticated: () {
          if (_returning) {
            _afterSignIn();
          } else {
            _go(_Stage.faceCheck);
          }
        });
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
                : _Stage.profile,
          ),
          onRetry: () => _go(_Stage.verificationProvider),
        );
      case _Stage.faceCheck:
        return VerificationProviderScreen(
          faceOnly: true,
          onComplete: () => _go(_Stage.profile),
          onCancel: _back,
        );
      case _Stage.waitlist:
        return WaitlistScreen(onAdmitted: () => _go(_Stage.profile));
      case _Stage.profile:
        // Publishing ends onboarding: history is cleared, so Back can't
        // reopen the empty form.
        return ProfileCreationScreen(onPublished: () {
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
                  onSignIn: () {
                    _returning = true;
                    _go(_Stage.signIn);
                  },
                ),
        );
    }
  }
}
