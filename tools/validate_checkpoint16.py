#!/usr/bin/env python3
"""Checkpoint 16 source checks; not a substitute for Flutter/device tests."""
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
checks = []
def source(path):
    return (root / path).read_text(encoding='utf-8')
def check(condition, description):
    checks.append((bool(condition), description))

pubspec = source('flutter_app/pubspec.yaml')
scaffold = source('tools/prepare_android_scaffold.sh')
native = source('flutter_app/android_widget/kotlin/CalendarAlerts.kt')
activity = source('flutter_app/android_widget/kotlin/MainActivity.kt')
location = source('flutter_app/lib/data/current_location_service.dart')
lookup = source('flutter_app/lib/data/district_lookup.dart')
calendar = source('flutter_app/lib/screens/calendar_screen.dart')
main = source('flutter_app/lib/main.dart')
holidays = source('flutter_app/lib/domain/state_holidays_2026.dart')
festival_ui = source('flutter_app/lib/screens/festivals_screen.dart')
check('version: 1.0.0+16' in pubspec, 'version is 1.0.0+16')
check('assets/data/district_boundaries.json' in pubspec, 'district geometry is bundled')
check('compute(findDistrict' in lookup, 'district parsing and geometry run in a background isolate')
check('repairSavedDistrict' in main and 'repairSavedDistrict' in location, 'old saved division labels are repaired without GPS')
check('getPositionStream' not in location and 'getCurrentPosition' in location, 'only one-shot foreground GPS')
check('CurrentLocationService().obtain' not in main, 'startup never requests GPS')
check('selectedDate' not in calendar and 'isSelected' not in calendar, 'Today-only highlighting retained')
check('DateTime get todayDate' in calendar, 'Today card retained')
settings = source('flutter_app/lib/data/app_settings_store.dart')
models = source('flutter_app/lib/domain/models.dart')
check('themeMode: ThemeMode.light' in main and
      'orElse: () => AppThemePreference.light' in settings, 'light default retained')
check('settings.customLocation.v1' in settings and 'hasValidCoordinates' in settings,
      'validated versioned saved coordinates retained')
check('String get cacheKey' in models, 'effective-coordinate cache key retained')
for path in ['screens/calendar_screen.dart', 'screens/festivals_screen.dart',
             'screens/my_days_screen.dart', 'domain/festival_engine.dart']:
    check('cacheKey' in source('flutter_app/lib/' + path), f'coordinate cache key in {path}')
check('majorFestivalsAsync' in calendar, 'background year calculation retained')
for name in ['today', 'upcoming']:
    check(f'android:previewLayout="@layout/widget_{name}"' in
          source(f'flutter_app/android_widget/res/xml/widget_{name}_info.xml'),
          f'{name} widget real-layout preview retained')
check((root/'flutter_app/android_widget/res/raw/morning_chime.wav').exists(),
      'gentle original chime retained')
check('setAndAllowWhileIdle' in native and 'setExactAndAllowWhileIdle' in native, 'precise reminders have an ordinary alarm fallback')
check('getBoolean("morning", true)' in native and '!prefs.contains("morning")' in activity,
      'morning defaults on without overwriting opt-outs')
check('POST_NOTIFICATIONS' in scaffold, 'ordinary notification permission present')
check('SCHEDULE_EXACT_ALARM' in scaffold and 'USE_EXACT_ALARM' not in scaffold, 'optional user-granted precise reminder permission')
check('ACCESS_BACKGROUND_LOCATION" tools:node="remove"' in scaffold, 'background GPS explicitly excluded')
check('documentLaunchMode="never"' in scaffold and 'singleTask' in scaffold,
      'one Android task with document tasks disabled')
check('finishAndRemoveTask' in activity, 'legacy duplicate tasks cleaned up')
for widget in ['TodayPanchangWidgetProvider', 'UpcomingWidgetProvider']:
    check('CalendarAlerts.launchIntent(context)' in source(f'flutter_app/android_widget/kotlin/{widget}.kt'),
          f'{widget} uses shared single-task launch intent')
check('CalendarSummaryWorker' in native and 'notificationBackground' in main,
      'closed-app offline summary refresh retained')
check('holidaysForRegion(year, region)' in festival_ui and "'Holidays'" in festival_ui,
      'one combined date-sorted Holidays view')
codes = set(__import__('re').findall(r'stateCode: "([A-Z]+)"', holidays))
check(len(codes) == 36, '2026 bundled holidays cover all 36 states/UTs')
check('year: 2026' in holidays, 'state holiday data remains year-specific')
for workflow in ['android', 'production']:
    text = source(f'.github/workflows/{workflow}.yml')
    check('validate_checkpoint16.py' in text and 'audit_android_permissions.py' in text,
          f'{workflow} workflow validates checkpoint 16 and merged permissions')
    check('build10-' not in text, f'{workflow} artifact labels identify build 16')

# Exercise real fallback data independently of Flutter toolchain availability.
data = json.loads(source('flutter_app/assets/data/district_boundaries.json'))
def inside(ring, x, y):
    result = False
    previous = ring[-1]
    for point in ring:
        if (point[1] > y) != (previous[1] > y):
            edge = (previous[0] - point[0]) * (y - point[1]) / (previous[1] - point[1]) + point[0]
            if x < edge:
                result = not result
        previous = point
    return result
def district(x, y):
    for name, bounds, polygons in data:
        if bounds[0] <= x <= bounds[2] and bounds[1] <= y <= bounds[3]:
            for polygon in polygons:
                if inside(polygon[0], x, y) and not any(inside(hole, x, y) for hole in polygon[1:]):
                    return name
    return None
check(district(74.29, 29.58) == 'Hanumangarh', 'saved coordinates near Hanumangarh resolve district, not division')
check(district(73.31, 28.02) == 'Bikaner', 'Bikaner city resolves its own district')
check(district(0, 0) is None, 'out-of-coverage coordinates do not invent a district')

native = source('flutter_app/android_widget/kotlin/DeviceLocation.kt')
calendar = source('flutter_app/lib/screens/calendar_screen.dart')
check('LocationAccuracy.high' in location and "'currentPosition'" in location,
      'high accuracy plus explicit native fallback')
check('LocationManager.GPS_PROVIDER' in native and 'LocationManager.NETWORK_PROVIDER' in native
      and 'LocationManager.FUSED_PROVIDER' not in native,
      'native fallback selects GPS/network rather than fused')
check('getCurrentLocation' in native and 'handler.removeCallbacks' in native
      and 'it.cancel()' in native and '45000L' in native,
      'native one-shot has bounded lifetime and cancellation cleanup')
check('requestGeneration' in native and 'generation == requestGeneration' in native,
      'obsolete provider callbacks cannot affect a later request')
check('panchang.time12(day!.sunriseUtc' in calendar and
      'panchang.time12(day!.sunsetUtc' in calendar and "'पु.'" in calendar and "'अप.'" in calendar,
      'Today sunrise and sunset are localized 12-hour times')
check('LocationDiagnostics.error' in location and '_showLocationDiagnostics' in calendar,
      'actual acquisition errors can be inspected and copied')
check('await festival.majorFestivalsAsync(DateTime.now().year, value)' not in main,
      'saving location is independent of year calculation')

alerts = source('flutter_app/android_widget/kotlin/CalendarAlerts.kt')
notification_ui = source('flutter_app/lib/screens/notifications_screen.dart')
check('morningDelivered' not in alerts or 'key + "Delivered"' in alerts, 'separate delivery markers')
check('if (show(context, id' in alerts and '.commit()' in alerts, 'delivery marker follows successful notification post')
check('CalendarAlerts.deliverDue(applicationContext)' in alerts, 'background cache completion retries delivery')
check('CalendarRecoveryWorker' in alerts and 'enqueueUniquePeriodicWork' in alerts, 'persistent missed-delivery recovery')
check('setOnlyAlertOnce(false)' in alerts, 'reused daily notification IDs can sound again')
check('channelEnabled(context)' in alerts and 'channel_blocked' in alerts, 'blocked notification channels are detected')
check('morningMinute' in notification_ui and 'eventsMinute' in notification_ui and 'showTimePicker' in notification_ui, 'independent persisted reminder times')
check("_test(" not in notification_ui and "_details(" not in notification_ui, 'production settings omit testing and diagnostic controls')
check('CalendarAlerts.test' in activity and 'SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED' in scaffold, 'test and precise permission bridges are registered')
check('lastRefreshError' in alerts and 'notificationSettings' in notification_ui, 'internal diagnostics retained and permission settings accessible')
check('testDebugUnitTest' in source('.github/workflows/android.yml') and 'testDebugUnitTest' in source('.github/workflows/production.yml'), 'both workflows run supported native regressions')

compatibility = source('flutter_app/android_widget/kotlin/TaskCompatibility.kt')
check('Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q' in compatibility and 'else info.id' in compatibility,
      'pre-Android-10 startup uses legacy task identifier')
check('info.taskId' not in activity and 'TaskCompatibility.isOtherAppTask' in activity,
      'startup delegates task identity to compatibility helper')
check('catch (error: RuntimeException)' in activity,
      'optional task cleanup cannot fail startup on OEM restrictions')
check('@Config(sdk = [24, 28])' in source('flutter_app/android_widget/test/TaskCompatibilityTest.kt')
      and '@Config(sdk = [29, 31])' in source('flutter_app/android_widget/test/TaskCompatibilityTest.kt'),
      'native regression tests exercise legacy and modern Android frameworks')

for ok, description in checks:
    print(('PASS' if ok else 'FAIL') + ' - ' + description)
sys.exit(0 if all(ok for ok, _ in checks) else 1)
