import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tunofy/main.dart';

void main() {
  testWidgets('App loads and shows MainShell', (WidgetTester tester) async {
    await tester.pumpWidget(const TunofyApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
