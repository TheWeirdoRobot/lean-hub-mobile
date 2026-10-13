import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_hub/data/connectivity_repository.dart';
import 'package:lean_hub/data/settings_repository.dart';
import 'package:lean_hub/models/app_settings.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('AppSettings storage', () {
    test('defaults: dark theme, standard quality, all sub-teams, Wi-Fi-only off', () {
      final s = AppSettings.fromStorage(const {});
      expect(s.theme, ThemePreference.dark);
      expect(s.photoQuality, PhotoQuality.standard);
      expect(s.defaultSubTeam, isNull);
      expect(s.wifiOnlyUploads, isFalse);
    });

    test('round-trips through storage', () {
      const s = AppSettings(
        wifiOnlyUploads: true,
        photoQuality: PhotoQuality.dataSaver,
        defaultSubTeam: 'CSE',
        theme: ThemePreference.light,
      );
      final back = AppSettings.fromStorage(s.toStorage());
      expect(back.wifiOnlyUploads, isTrue);
      expect(back.photoQuality, PhotoQuality.dataSaver);
      expect(back.defaultSubTeam, 'CSE');
      expect(back.theme, ThemePreference.light);
    });

    test('unknown saved values fall back instead of crashing', () {
      final s = AppSettings.fromStorage(const {
        'photo_quality': 'ultra',
        'theme': 'sepia',
        'default_sub_team': 'Software', // no longer a sub-team
      });
      expect(s.photoQuality, PhotoQuality.standard);
      expect(s.theme, ThemePreference.dark);
      expect(s.defaultSubTeam, isNull);
    });

    test('copyWith can clear the default sub-team', () {
      const s = AppSettings(defaultSubTeam: 'Mechanical');
      expect(s.copyWith(defaultSubTeam: () => null).defaultSubTeam, isNull);
      expect(s.copyWith(wifiOnlyUploads: true).defaultSubTeam, 'Mechanical');
    });
  });

  test('SettingsRepository persists across reloads and notifies', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();

    final first = await SettingsRepository.load();
    var notified = 0;
    first.addListener(() => notified++);
    await first.update(first.value.copyWith(
      theme: ThemePreference.system,
      defaultSubTeam: () => 'Electrical',
    ));
    expect(notified, 1);

    final reloaded = await SettingsRepository.load();
    expect(reloaded.value.theme, ThemePreference.system);
    expect(reloaded.value.defaultSubTeam, 'Electrical');
  });

  test('Wi-Fi and ethernet count as unmetered; cellular and none do not', () {
    expect(ConnectivityRepository.isUnmetered([ConnectivityResult.wifi]), isTrue);
    expect(ConnectivityRepository.isUnmetered(
        [ConnectivityResult.mobile, ConnectivityResult.ethernet]), isTrue);
    expect(ConnectivityRepository.isUnmetered([ConnectivityResult.mobile]), isFalse);
    expect(ConnectivityRepository.isUnmetered([ConnectivityResult.none]), isFalse);
  });
}
