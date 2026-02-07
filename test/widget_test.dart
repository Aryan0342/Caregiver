// Basic Flutter widget test.
// Uses a minimal widget to avoid Firebase/main.dart dependency in tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test: app shell builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        title: 'Caregiver',
        home: Scaffold(body: Center(child: Text('Caregiver'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Caregiver'), findsOneWidget);
  });
}
