/// Environment configuration for CampusX.
///
/// SECURITY: nothing sensitive is hardcoded here. Every value is injected at
/// build time via --dart-define (or --dart-define-from-file) so secrets never
/// sit in source control or get baked permanently into a shipped binary you
/// can't rotate. The `defaultValue` below only exists so a fresh checkout
/// still runs for local development; ALWAYS override it for a real build.
///
/// Build for release with your own keys:
///   flutter build windows --release ^
///     --dart-define=SUPABASE_URL=https://your-project.supabase.co ^
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=your_supabase_publishable_key ^
///     --dart-define=GEMINI_API_KEY=your_gemini_key
///
/// Or keep them in a git-ignored file (see env.example.json) and run:
///   flutter build windows --release --dart-define-from-file=env.json
class AppEnv {
  // Supabase Configuration.
  // The anon/publishable key is safe to ship in a client app by Supabase's
  // own design (it's gated by Row Level Security on the server) — but it
  // should still be injected, not hardcoded, so you can rotate projects
  // without touching source.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://empmoatbedkaxopxxihh.supabase.co',
  );
  static const String _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  // Backward-compatible with older env files/build commands.
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get supabasePublishableKey =>
      _supabasePublishableKey.isNotEmpty ? _supabasePublishableKey : _supabaseAnonKey;

  // Custom URI used by Google OAuth to return to the CampusX desktop app.
  // Add this exact URI to Supabase Auth -> URL Configuration -> Redirect URLs.
  static const String authRedirectUrl = 'campusx://auth-callback';

  // Gemini AI / Pegasus Assistant Configuration.
  // Unlike the Supabase anon key, this key is NOT safe to leave in a public
  // repo or a shipped .exe long-term — anyone can pull it out with `strings`.
  // Rotate it in Google AI Studio and pass the new one via --dart-define at
  // build time. Never commit a real key here.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Optional comma-separated fallback keys for automatic failover when one
  /// key hits its rate limit, e.g.
  ///   --dart-define=GEMINI_API_KEYS=key1,key2,key3
  static const String _rawGeminiKeyList = String.fromEnvironment(
    'GEMINI_API_KEYS',
    defaultValue: '',
  );

  static List<String> get geminiApiKeys {
    if (_rawGeminiKeyList.trim().isNotEmpty) {
      return _rawGeminiKeyList
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();
    }
    return geminiApiKey.isNotEmpty ? [geminiApiKey] : [];
  }

  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );

  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Thinking level for Gemini 3.x models: 'low' keeps Pegasus fast and
  /// cheap for everyday chat; raise to 'medium'/'high' later for tasks that
  /// need deeper multi-step reasoning. (Gemini 3.x replaced the old numeric
  /// thinkingBudget with this string enum; 'minimal' is rejected by the API.)
  static const String geminiThinkingLevel = String.fromEnvironment(
    'GEMINI_THINKING_LEVEL',
    defaultValue: 'low',
  );

  /// Caps a single reply's length — keeps runaway responses (and runaway
  /// token bills) in check.
  static const int geminiMaxOutputTokens = 2048;

  /// How many past turns (user+model pairs) to resend as context. Higher
  /// keeps longer conversations coherent, but cost grows with this number
  /// since the whole window is resent every message.
  static const int geminiMaxHistoryTurns = 12;

  static bool get hasGeminiKey => geminiApiKeys.isNotEmpty;

  // App Metadata
  static const String appName = 'CampusX';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Where your campus actually talks';
}
