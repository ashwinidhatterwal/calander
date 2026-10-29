import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/main.dart';

void main() {
  testWidgets('Hindi-first app shell renders in light mode by default', (tester) async {
    await tester.pumpWidget(const HinduCalendarApp(holikaOverrides: {}));
    await tester.pump();

    expect(find.text('हिन्दू कैलेंडर'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month), findsWidgets);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    await tester.tap(find.text('ज्ञान'));
    await tester.pump();
    expect(find.text('आज का ज्ञान'), findsOneWidget);

    final context = tester.element(find.text('आज का ज्ञान').first);
    expect(Theme.of(context).brightness, Brightness.light);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
