enum AppLocalePreference {
  system,
  korean,
  english,
}

extension AppLocalePreferenceX on AppLocalePreference {
  String get storageValue => switch (this) {
    AppLocalePreference.system => 'system',
    AppLocalePreference.korean => 'ko',
    AppLocalePreference.english => 'en',
  };

  static AppLocalePreference fromStorage(String? value) {
    return switch (value) {
      'ko' => AppLocalePreference.korean,
      'en' => AppLocalePreference.english,
      _ => AppLocalePreference.system,
    };
  }
}
