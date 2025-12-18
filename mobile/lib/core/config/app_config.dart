import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    // 1. Get from build arguments: --dart-define=API_BASE_URL=...
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // 2. Fallback for local development
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
    } catch (e) {
      // Platform.isAndroid might throw on web if not guarded by kIsWeb,
      // but we guarded it above.
    }

    return 'http://localhost:8080';
  }

  static String get apiUrl => '$baseUrl/api';
}
