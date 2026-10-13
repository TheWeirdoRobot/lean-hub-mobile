import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:lean_hub/models/taxonomy.dart';

void main() {
  group('statusToValue (matches the website)', () {
    test('lowercases and joins words with underscores', () {
      expect(statusToValue('In Progress'), 'in_progress');
      expect(statusToValue('Not Started'), 'not_started');
      expect(statusToValue('Done'), 'done');
    });

    test('collapses runs of whitespace like /\\s+/g', () {
      expect(statusToValue('Waiting  on\tParts'), 'waiting_on_parts');
    });

    test('statusLabelFromValue reverses simple slugs', () {
      expect(statusLabelFromValue('in_progress'), 'In Progress');
      expect(statusLabelFromValue('blocked'), 'Blocked');
    });
  });

  group('StatusCatalog', () {
    test('falls back to web defaults when custom_statuses is empty', () {
      final c = StatusCatalog(const []);
      expect(c.options.map((s) => s.name),
          ['Not Started', 'In Progress', 'Review', 'Done']);
      expect(c.resolve('in_progress').color, const Color(0xFFEAB308));
    });

    test('parses rows and sorts by column_order', () {
      final c = StatusCatalog([
        StatusOption.fromJson({'name': 'Done', 'color': '#22C55E', 'column_order': 2}),
        StatusOption.fromJson({'name': 'Blocked', 'color': '#FF0000', 'column_order': 0}),
      ]);
      expect(c.options.map((s) => s.value), ['blocked', 'done']);
      expect(c.resolve('blocked').color, const Color(0xFFFF0000));
    });

    test('unknown slugs resolve to a readable grey option', () {
      final s = StatusCatalog.defaults.resolve('waiting_on_parts');
      expect(s.name, 'Waiting On Parts');
      expect(s.value, 'waiting_on_parts');
    });

    test('optionsIncluding adds an unknown current status once', () {
      final c = StatusCatalog.defaults;
      expect(c.optionsIncluding('done'), hasLength(4));
      final withUnknown = c.optionsIncluding('legacy');
      expect(withUnknown, hasLength(5));
      expect(withUnknown.last.value, 'legacy');
    });
  });

  group('SubTeams', () {
    test('includes the four sub-teams in order', () {
      expect(SubTeams.all.map((t) => t.name),
          ['Full Team', 'Mechanical', 'Electrical', 'CSE']);
    });

    test('unknown or null resolves to Full Team, like subTeamOf() on the web', () {
      expect(SubTeams.resolve(null).name, 'Full Team');
      expect(SubTeams.resolve('Software').name, 'Full Team');
      expect(SubTeams.resolve('Mechanical').abbr, 'MT');
      expect(SubTeams.resolve('CSE').color, const Color(0xFF5FBFC9));
    });
  });

  group('phases and colors', () {
    test('PhaseCatalog falls back to defaults and colors unknown phases grey', () {
      final c = PhaseCatalog(const []);
      expect(c.options.first.name, 'Research');
      expect(c.colorFor('Design'), const Color(0xFFA79BE8));
      expect(c.colorFor('Nope'), const Color(0xFF94A3B8));
    });

    test('parseHexColor handles #, no #, and garbage', () {
      expect(parseHexColor('#7C3AED'), const Color(0xFF7C3AED));
      expect(parseHexColor('0D0D1A'), const Color(0xFF0D0D1A));
      expect(parseHexColor('red', fallback: const Color(0xFF000001)),
          const Color(0xFF000001));
      expect(parseHexColor(null), const Color(0xFF94A3B8));
    });
  });
}
