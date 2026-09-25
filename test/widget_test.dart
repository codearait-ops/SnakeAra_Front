import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snake_game/main.dart';

void main() {
  testWidgets('App launches and shows menu screen', (WidgetTester tester) async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SnakeApp());
    await tester.pumpAndSettle();

    // Verify the menu title is displayed
    expect(find.text('SNAKE'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('LEADERBOARD'), findsOneWidget);
  });
}
