import 'package:flutter_test/flutter_test.dart';
import 'package:lean_hub/app.dart';
import 'package:lean_hub/core/widgets.dart';
import 'package:lean_hub/models/taxonomy.dart';
import 'package:lean_hub/router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('authRedirect', () {
    test('signed-out users are sent to sign-in', () {
      expect(authRedirect(signedIn: false, location: '/tasks'), '/sign-in');
      expect(authRedirect(signedIn: false, location: '/tasks/abc'), '/sign-in');
      expect(authRedirect(signedIn: false, location: '/sign-in'), isNull);
    });

    test('signed-in users skip sign-in and are otherwise left alone', () {
      expect(authRedirect(signedIn: true, location: '/sign-in'), '/tasks');
      expect(authRedirect(signedIn: true, location: '/settings'), isNull);
    });
  });

  testWidgets('status Pill shows the custom status name', (tester) async {
    final status = StatusCatalog.defaults.resolve('in_progress');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Pill(label: status.name, color: status.color)),
    ));
    expect(find.text('In Progress'), findsOneWidget);
  });

  testWidgets('app explains missing Supabase config instead of crashing',
      (tester) async {
    await tester.pumpWidget(const MissingConfigApp());
    expect(find.text('Supabase is not configured'), findsOneWidget);
  });
}
