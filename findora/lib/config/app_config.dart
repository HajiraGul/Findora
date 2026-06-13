import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Optional compile-time override — use this for a physical device on your LAN:
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.103:5000/api
  static const _override = String.fromEnvironment('API_BASE_URL');

  /// Base URL of the Findora backend.
  ///
  /// The Android emulator can't see the host's `127.0.0.1` — it reaches the host
  /// machine through the special alias `10.0.2.2`. The iOS simulator (and
  /// desktop) use the host loopback directly. A `--dart-define=API_BASE_URL`
  /// override always wins (needed for real devices pointing at the LAN IP).
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://127.0.0.1:5000/api';
  }
}
