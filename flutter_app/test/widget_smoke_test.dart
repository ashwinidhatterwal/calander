import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/main.dart';

void main() {
  testWidgets('Hindi-first app shell renders', (tester) async {
    await tester.pumpWidget(const HinduCalendarApp(holikaOverrides: {}));
    await tester.pump();
    expect(find.text('हिन्दू कैलेंडर'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month), findsWidgets);
  });
}
