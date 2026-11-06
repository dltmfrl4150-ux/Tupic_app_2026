import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/locale_preference.dart';

const _kLocaleKey = 'tupic_locale_preference';

/// Owns language preference and resolves MaterialApp.locale.
class LocaleController extends ChangeNotifier {
  LocaleController();

  AppLocalePreference _preference = AppLocalePreference.system;
  SharedPreferences? _prefs;
  bool _ready = false;

  AppLocalePreference get preference => _preference;
  bool get isReady => _ready;

  /// Null means follow device/browser locale via MaterialApp resolution.
  Locale? get localeOverride => switch (_preference) {
    AppLocalePreference.system => null,
    AppLocalePreference.korean => const Locale('ko'),
    AppLocalePreference.english => const Locale('en'),
  };

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _preference = AppLocalePreferenceX.fromStorage(_prefs!.getString(_kLocaleKey));
    _ready = true;
    notifyListeners();
  }

  Future<void> setPreference(AppLocalePreference value) async {
    if (_preference == value) return;
    _preference = value;
    notifyListeners();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_kLocaleKey, value.storageValue);
  }
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found');
    return scope!.notifier!;
  }
}
