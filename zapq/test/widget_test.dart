// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zapq/core/theme/app_theme.dart';

void main() {
  testWidgets('ZapQ app theme test', (WidgetTester tester) async {
    // Create a simple test app with our theme
    final testApp = MaterialApp(
      title: 'ZapQ Test',
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('ZapQ'),
              Text('Smart Virtual Queue & Shop Management'),
            ],
          ),
        ),
      ),
    );

    // Build our test app and trigger a frame.
    await tester.pumpWidget(testApp);

    // Verify that our app displays the expected text
    expect(find.text('ZapQ'), findsOneWidget);
    expect(find.text('Smart Virtual Queue & Shop Management'), findsOneWidget);
    
    // Verify theme is applied correctly
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme, isNotNull);
  });
}
