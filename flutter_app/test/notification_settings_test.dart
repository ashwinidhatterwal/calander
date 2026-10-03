import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/data/notification_service.dart';
import 'package:hindu_calendar/screens/notifications_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> settings;
  late List<MethodCall> calls;
  setUp(() {
    calls = [];
    settings = {
      'morning': true,
      'events': true,
      'sound': true,
      'morningMinute': 375,
      'eventsMinute': 1145,
      'permitted': true,
      'channelEnabled': true,
      'precise': true,
      'cacheReady': true,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NotificationService.channel, (call) async {
          calls.add(call);
          if (call.method == 'status') return settings;
          if (call.method == 'configure') {
            settings.addAll(Map<String, dynamic>.from(call.arguments as Map));
          }
          if (call.method == 'testNotification') return settings['permitted'];
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NotificationService.channel, null);
  });
  Future<void> open(WidgetTester tester, AppLanguage language) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(language: language, onRefresh: () async {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('separate times use Hindi prefixes and survive toggle changes', (
    tester,
  ) async {
    await open(tester, AppLanguage.hi);
    expect(find.text('6:15 पु.'), findsOneWidget);
    expect(find.text('7:05 अप.'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    final configured =
        calls.lastWhere((c) => c.method == 'configure').arguments as Map;
    expect(configured['morningMinute'], 375);
    expect(configured['eventsMinute'], 1145);
    expect(configured['events'], true);
  });
  testWidgets('immediate and delayed tests use separate native requests', (
    tester,
  ) async {
    await open(tester, AppLanguage.en);
    await tester.scrollUntilVisible(
      find.text('Send test notification now'),
      220,
    );
    await tester.tap(find.text('Send test notification now'));
    await tester.pumpAndSettle();
    expect(
      (calls.lastWhere((c) => c.method == 'testNotification').arguments
          as Map)['delayed'],
      false,
    );
    await tester.scrollUntilVisible(find.text('Test in one minute'), 150);
    await tester.tap(find.text('Test in one minute'));
    await tester.pumpAndSettle();
    expect(
      (calls.lastWhere((c) => c.method == 'testNotification').arguments
          as Map)['delayed'],
      true,
    );
  });
  testWidgets('blocked test reports the failure and offers system settings', (
    tester,
  ) async {
    settings['permitted'] = false;
    await open(tester, AppLanguage.en);
    await tester.scrollUntilVisible(
      find.text('Send test notification now'),
      200,
    );
    await tester.tap(find.text('Send test notification now'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Notification permission or the channel is blocked. Open phone settings below.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Notifications are blocked'),
      150,
    );
    await tester.tap(find.text('Notifications are blocked'));
    await tester.pumpAndSettle();
    expect(calls.any((c) => c.method == 'notificationSettings'), true);
  });
  test('configure transports both user-selected minutes', () async {
    await NotificationService.configure(
      true,
      false,
      true,
      morningMinute: 0,
      eventsMinute: 720,
    );
    final args = calls.single.arguments as Map;
    expect(args['morningMinute'], 0);
    expect(args['eventsMinute'], 720);
  });
}
