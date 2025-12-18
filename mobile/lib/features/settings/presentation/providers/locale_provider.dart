import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current [Locale] of the app.
/// If null, the system locale is used.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    return null; // Default to system
  }

  void setLocale(Locale? locale) {
    state = locale;
  }

  void setEnglish() {
    state = const Locale('en');
  }

  void setChinese() {
    state = const Locale('zh');
  }

  void setSystem() {
    state = null;
  }
}
