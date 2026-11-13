/// Central app configuration.
///
/// IMPORTANT — NAME: The founder finalizes the product name LAST.
/// [appName] is the single source of truth for the display name across the
/// entire app. Every screen, string, and legal line reads from here — never
/// hard-code the name anywhere else. ASCII contexts (deep-link scheme,
/// domains, handles) use [appNameAscii].
class AppConfig {
  AppConfig._();

  /// Display name (working name). Change this one constant to rename the app.
  static const String appName = 'Cariño';

  /// ASCII form for the URL scheme, domains and store/search metadata.
  static const String appNameAscii = 'Carino';

  /// Deep-link scheme (ASCII only, per blueprint NAV & IA sheet).
  static const String urlScheme = 'carino';

  /// Hard age floor. Under-21 can never create an account or reach the tabs.
  static const int minimumAge = 21;

  /// Subscription product line name ("Cariño Plus").
  static String get plusName => '$appName Plus';

  /// Tagline used on Welcome (S-001).
  static const String tagline =
      'Meet someone who wants your kind of connection — and feel the chemistry before meeting.';

  /// Asset paths (approved imagery set A1–A3, see SCREEN IMAGERY sheet).
  static const String assetHeroWelcome = 'assets/images/hero_welcome.jpg'; // A1
  static const String assetBackdropDiscover = 'assets/images/backdrop_discover.jpg'; // A2
  static const String assetBackdropMatch = 'assets/images/backdrop_match.jpg'; // A3
  static const String assetLogo = 'assets/images/logo.png';
  static const String assetAppIcon = 'assets/images/app_icon.png';

  /// Feature flags for the scaffold. Live values come from BackendService
  /// remote config in production (blueprint S-058 Admin — feature flags).
  static const bool sparkSessionsEnabled = true;
  static const bool funModeEnabled = true;
}
