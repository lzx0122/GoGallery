import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: Text(l10n.settingsSystemMode),
            subtitle: Text(l10n.settingsSystemModeDescription),
            trailing: Switch.adaptive(
              value: currentTheme == ThemeMode.system,
              onChanged: (bool value) {
                if (value) {
                  ref.read(themeProvider.notifier).setSystem();
                } else {
                  // 當關閉系統模式時，保持當前的視覺亮度
                  final brightness = MediaQuery.of(context).platformBrightness;
                  if (brightness == Brightness.dark) {
                    ref.read(themeProvider.notifier).setDark();
                  } else {
                    ref.read(themeProvider.notifier).setLight();
                  }
                }
              },
            ),
          ),
          if (currentTheme != ThemeMode.system)
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(l10n.settingsDarkMode),
              trailing: Switch.adaptive(
                value: currentTheme == ThemeMode.dark,
                onChanged: (bool value) {
                  if (value) {
                    ref.read(themeProvider.notifier).setDark();
                  } else {
                    ref.read(themeProvider.notifier).setLight();
                  }
                },
              ),
            ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            trailing: PopupMenuButton<Locale?>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (Locale? newValue) {
                if (newValue == null) {
                  ref.read(localeProvider.notifier).setSystem();
                } else if (newValue.languageCode == 'en') {
                  ref.read(localeProvider.notifier).setEnglish();
                } else if (newValue.languageCode == 'zh') {
                  ref.read(localeProvider.notifier).setChinese();
                }
              },
              itemBuilder: (BuildContext context) {
                bool isSelected(Locale? value) {
                  if (value == null && currentLocale == null) return true;
                  if (value != null &&
                      currentLocale != null &&
                      value.languageCode == currentLocale.languageCode) {
                    return true;
                  }
                  return false;
                }

                PopupMenuItem<Locale?> buildItem(Locale? value, String text) {
                  final selected = isSelected(value);
                  final colorScheme = Theme.of(context).colorScheme;
                  return PopupMenuItem<Locale?>(
                    value: value,
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            text,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: selected ? FontWeight.bold : null,
                                  color: selected ? colorScheme.primary : null,
                                ),
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                      ],
                    ),
                  );
                }

                return [
                  buildItem(null, l10n.settingsSystemMode),
                  buildItem(const Locale('en'), 'English'),
                  buildItem(const Locale('zh'), '繁體中文'),
                ];
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLocale == null
                          ? l10n.settingsSystemMode
                          : currentLocale.languageCode == 'en'
                          ? 'English'
                          : '繁體中文',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
