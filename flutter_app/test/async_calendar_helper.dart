import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
Future<void> settleCalendar(WidgetTester tester) async {
  for (var i = 0; i < 150; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 20));
    if (find.byType(CircularProgressIndicator, skipOffstage: false).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}
