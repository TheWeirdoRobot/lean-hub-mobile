import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// App settings persisted with shared_preferences. A [ChangeNotifier] so the
/// theme and screens update as soon as a setting changes.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository._(this._prefs, this._value);

  static final _keys = const AppSettings().toStorage().keys.toSet();

  /// Reads saved settings; call once in main() before runApp.
  static Future<SettingsRepository> load() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: SharedPreferencesWithCacheOptions(allowList: _keys),
    );
    return SettingsRepository._(
      prefs,
      AppSettings.fromStorage({for (final k in _keys) k: prefs.get(k)}),
    );
  }

  final SharedPreferencesWithCache _prefs;
  AppSettings _value;

  AppSettings get value => _value;

  Future<void> update(AppSettings next) async {
    _value = next;
    notifyListeners();
    for (final MapEntry(:key, :value) in next.toStorage().entries) {
      switch (value) {
        case bool v:
          await _prefs.setBool(key, v);
        case String v:
          await _prefs.setString(key, v);
      }
    }
  }
}
