import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test builds a basic app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Elimu Pepe Smoke Test'),
          ),
        ),
      ),
    );

    expect(find.text('Elimu Pepe Smoke Test'), findsOneWidget);
  });
}
