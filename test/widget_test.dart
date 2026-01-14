// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ai_vehicle_counter/main.dart';
import 'package:ai_vehicle_counter/ui/themes/theme_provider.dart';

void main() {
  testWidgets('App boots and shows splash title', (WidgetTester tester) async {
    // Build app with the same ThemeProvider setup used in main().
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const VehicleCounterApp(),
      ),
    );

    // Splash screen title should be visible initially.
    expect(find.text('AI Vehicle Counter'), findsOneWidget);
  });
}
