import 'taxonomy.dart';

/// Resize/re-encode presets for uploaded photos.
enum PhotoQuality {
  high('High', 'Up to 2048 px · best for close-up detail', 2048, 85),
  standard('Standard', 'Up to 1600 px · good balance', 1600, 75),
  dataSaver('Data saver', 'Up to 1024 px · smallest uploads', 1024, 60);

  const PhotoQuality(this.label, this.description, this.maxDimension, this.jpegQuality);

  final String label;
  final String description;
  final int maxDimension;
  final int jpegQuality;
}

enum ThemePreference {
  dark('Dark'),
  light('Light'),
  system('Match iPhone');

  const ThemePreference(this.label);

  final String label;
}

/// Device-local preferences. Not synced to Supabase.
class AppSettings {
  const AppSettings({
    this.wifiOnlyUploads = false,
    this.photoQuality = PhotoQuality.standard,
    this.defaultSubTeam,
    this.theme = ThemePreference.dark,
  });

  final bool wifiOnlyUploads;
  final PhotoQuality photoQuality;

  /// Sub-team pre-selected in My Tasks; null means all sub-teams.
  final String? defaultSubTeam;
  final ThemePreference theme;

  AppSettings copyWith({
    bool? wifiOnlyUploads,
    PhotoQuality? photoQuality,
    String? Function()? defaultSubTeam,
    ThemePreference? theme,
  }) =>
      AppSettings(
        wifiOnlyUploads: wifiOnlyUploads ?? this.wifiOnlyUploads,
        photoQuality: photoQuality ?? this.photoQuality,
        defaultSubTeam: defaultSubTeam != null ? defaultSubTeam() : this.defaultSubTeam,
        theme: theme ?? this.theme,
      );

  // Stored as plain strings so a renamed or removed option falls back to its
  // default instead of crashing on launch.

  Map<String, Object> toStorage() => {
        'wifi_only_uploads': wifiOnlyUploads,
        'photo_quality': photoQuality.name,
        'default_sub_team': defaultSubTeam ?? '',
        'theme': theme.name,
      };

  factory AppSettings.fromStorage(Map<String, Object?> values) {
    const d = AppSettings();
    T byName<T extends Enum>(List<T> all, Object? name, T fallback) =>
        all.where((e) => e.name == name).firstOrNull ?? fallback;
    final team = values['default_sub_team'];
    return AppSettings(
      wifiOnlyUploads: values['wifi_only_uploads'] as bool? ?? d.wifiOnlyUploads,
      photoQuality: byName(PhotoQuality.values, values['photo_quality'], d.photoQuality),
      defaultSubTeam: SubTeams.all.any((t) => t.name == team) ? team as String : null,
      theme: byName(ThemePreference.values, values['theme'], d.theme),
    );
  }
}
