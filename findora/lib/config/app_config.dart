class AppConfig {
  // Optional compile-time override — use this to point at a local backend during
  // development:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api   (Android emulator)
  //   flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5000/api  (iOS sim / desktop)
  static const _override = String.fromEnvironment('API_BASE_URL');

  /// Base URL of the deployed Findora backend.
  static const _production = 'https://findora-nine.vercel.app/api';

  /// Base URL of the Findora backend. A `--dart-define=API_BASE_URL` override
  /// always wins (use it to run against a local backend); otherwise the app
  /// talks to the deployed backend.
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    return _production;
  }
}
