// Sub-teams, statuses, phases and priorities — the mobile equivalent of the
// website's teams.js + useCustomStatuses.js + useCustomPhases.js. Every screen
// goes through this file so display names, colors and fallbacks stay in one place.
import 'dart:ui' show Color;

/// Parses `#RRGGBB` (or `RRGGBB`) into a [Color]; returns [fallback] if invalid.
Color parseHexColor(String? hex, {Color fallback = const Color(0xFF94A3B8)}) {
  if (hex == null) return fallback;
  final clean = hex.trim().replaceFirst('#', '');
  if (clean.length != 6) return fallback;
  final value = int.tryParse(clean, radix: 16);
  return value == null ? fallback : Color(0xFF000000 | value);
}

const _unknownColor = Color(0xFF94A3B8);

// ─────────────────────────────────────────
// Sub-teams
// ─────────────────────────────────────────

class SubTeam {
  const SubTeam(this.name, this.abbr, this.color);
  final String name;
  final String abbr;
  final Color color;
}

class SubTeams {
  SubTeams._();

  static const fullTeam = 'Full Team';

  // Must match SUB_TEAMS in lean-hub/src/lib/teams.js.
  static const all = <SubTeam>[
    SubTeam('Full Team', 'FT', Color(0xFF6CA6E8)),
    SubTeam('Mechanical', 'MT', Color(0xFFDE9260)),
    SubTeam('Electrical', 'ET', Color(0xFFD9A73F)),
    SubTeam('CSE', 'CSE', Color(0xFF5FBFC9)),
  ];

  /// Looks up a sub-team by its stored name. Like subTeamOf() on the web,
  /// anything unknown (including null) is treated as Full Team.
  static SubTeam resolve(String? name) {
    for (final t in all) {
      if (t.name == name) return t;
    }
    return all.first;
  }
}

// ─────────────────────────────────────────
// Statuses (custom_statuses table)
// ─────────────────────────────────────────

/// Maps a display name to the slug stored in tasks.status, exactly like
/// statusToValue() on the web: "In Progress" → "in_progress".
String statusToValue(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

/// Best-effort display name for a slug that has no custom_statuses row.
String statusLabelFromValue(String value) => value
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

class StatusOption {
  const StatusOption({required this.name, required this.color, this.order = 0});

  factory StatusOption.fromJson(Map<String, dynamic> json) => StatusOption(
        name: json['name'] as String? ?? '',
        color: parseHexColor(json['color'] as String?),
        order: (json['column_order'] as num?)?.toInt() ?? 0,
      );

  final String name;
  final Color color;
  final int order;

  /// The slug written to tasks.status.
  String get value => statusToValue(name);
}

/// Same defaults as DEFAULT_STATUSES in useCustomStatuses.js.
const defaultStatuses = <StatusOption>[
  StatusOption(name: 'Not Started', color: Color(0xFF94A3B8), order: 0),
  StatusOption(name: 'In Progress', color: Color(0xFFEAB308), order: 1),
  StatusOption(name: 'Review', color: Color(0xFF3B82F6), order: 2),
  StatusOption(name: 'Done', color: Color(0xFF22C55E), order: 3),
];

class StatusCatalog {
  StatusCatalog(List<StatusOption> options)
      : options = List.unmodifiable(
            (options.isEmpty ? defaultStatuses : options).toList()
              ..sort((a, b) => a.order.compareTo(b.order)));

  static final defaults = StatusCatalog(defaultStatuses);

  final List<StatusOption> options;

  /// Finds the option for a stored slug. Slugs with no matching row (e.g. a
  /// status that was renamed in Admin) still get a readable label.
  StatusOption resolve(String value) {
    for (final s in options) {
      if (s.value == value) return s;
    }
    return StatusOption(
      name: statusLabelFromValue(value),
      color: _unknownColor,
      order: options.length,
    );
  }

  /// Options for a picker, including [current] if it isn't a known status.
  List<StatusOption> optionsIncluding(String current) {
    if (options.any((s) => s.value == current)) return options;
    return [...options, resolve(current)];
  }
}

// ─────────────────────────────────────────
// Phases (custom_phases table)
// ─────────────────────────────────────────

class PhaseOption {
  const PhaseOption({required this.name, required this.color});

  factory PhaseOption.fromJson(Map<String, dynamic> json) => PhaseOption(
        name: json['name'] as String? ?? '',
        color: parseHexColor(json['color'] as String?,
            fallback: const Color(0xFF7C3AED)),
      );

  final String name;
  final Color color;
}

/// Same defaults as DEFAULT_PHASES in useCustomPhases.js.
const defaultPhases = <PhaseOption>[
  PhaseOption(name: 'Research', color: Color(0xFF6CA6E8)),
  PhaseOption(name: 'Design', color: Color(0xFFA79BE8)),
  PhaseOption(name: 'Fabrication', color: Color(0xFFDE9260)),
  PhaseOption(name: 'Testing', color: Color(0xFF6BC77A)),
  PhaseOption(name: 'Competition', color: Color(0xFFD9A73F)),
];

class PhaseCatalog {
  PhaseCatalog(List<PhaseOption> options)
      : options = List.unmodifiable(options.isEmpty ? defaultPhases : options);

  static final defaults = PhaseCatalog(defaultPhases);

  final List<PhaseOption> options;

  Color colorFor(String name) {
    for (final p in options) {
      if (p.name == name) return p.color;
    }
    return _unknownColor;
  }
}

// ─────────────────────────────────────────
// Priorities (fixed check constraint on tasks.priority)
// ─────────────────────────────────────────

class Priority {
  Priority._();

  static const values = ['low', 'medium', 'high', 'critical'];

  static String label(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  static Color color(String value) => switch (value) {
        'low' => const Color(0xFF94A3B8),
        'medium' => const Color(0xFF3B82F6),
        'high' => const Color(0xFFF97316),
        'critical' => const Color(0xFFF85149),
        _ => _unknownColor,
      };
}
