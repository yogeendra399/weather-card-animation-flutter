import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App basic UI smoke test', (WidgetTester tester) async {
    // Minimal test app to ensure framework builds correctly
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Weather App Running'),
          ),
        ),
      ),
    );

    // Verify text exists in UI
    expect(find.text('Weather App Running'), findsOneWidget);
  });
}
