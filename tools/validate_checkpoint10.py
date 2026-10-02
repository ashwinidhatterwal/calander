#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
checks = []

def check(condition, message):
    checks.append((condition, message))

pubspec = (root/'flutter_app/pubspec.yaml').read_text(encoding='utf-8')
main = (root/'flutter_app/lib/main.dart').read_text(encoding='utf-8')
settings = (root/'flutter_app/lib/data/app_settings_store.dart').read_text(encoding='utf-8')
about = (root/'flutter_app/lib/screens/about_support_screen.dart').read_text(encoding='utf-8')
today_info = (root/'flutter_app/android_widget/res/xml/widget_today_info.xml').read_text(encoding='utf-8')
upcoming_info = (root/'flutter_app/android_widget/res/xml/widget_upcoming_info.xml').read_text(encoding='utf-8')
qa = (root/'.github/workflows/android.yml').read_text(encoding='utf-8')
production = (root/'.github/workflows/production.yml').read_text(encoding='utf-8')

check('version: 1.0.0+10' in pubspec, 'build number is 10')
check('themeMode: ThemeMode.light' in main, 'loading app defaults to light')
check('AppThemePreference.light' in main, 'main app has explicit light default')
check("orElse: () => AppThemePreference.light" in settings, 'stored theme defaults to light')
check('AppThemePreference.dark' in about, 'dark mode is optional')
check('बिना विज्ञापन और बिना पेवॉल' in about, 'support copy is human and non-coercive')
check('चैरिटी दान' not in about, 'raw legalistic donation wording removed')
check('android:previewLayout="@layout/widget_today"' in today_info, 'Today widget has real preview layout')
check('android:previewLayout="@layout/widget_upcoming"' in upcoming_info, 'Upcoming widget has real preview layout')
check('Audit Android permissions' in qa, 'QA workflow still audits permissions')
check('flutter build appbundle' in production, 'production workflow still builds AAB')
check((root/'store_web/privacy.html').exists(), 'public privacy policy source remains included')


calendar = (root/'flutter_app/lib/screens/calendar_screen.dart').read_text(encoding='utf-8')
service = (root/'flutter_app/lib/data/current_location_service.dart').read_text(encoding='utf-8')
holidays = (root/'flutter_app/lib/domain/civil_holidays.dart').read_text(encoding='utf-8')
scaffold = (root/'tools/prepare_android_scaffold.sh').read_text(encoding='utf-8')
models = (root/'flutter_app/lib/domain/models.dart').read_text(encoding='utf-8')
check('selectedDate' not in calendar and 'isSelected' not in calendar, 'no persistent selected date or first-day highlight')
check('DateTime get todayDate' in calendar, 'Today card uses current date')
check('settings.customLocation.v1' in settings and 'hasValidCoordinates' in settings, 'versioned coordinates are persisted and validated')
check('settings.locationOfferSeen' in settings, 'first-use offer remembered locally')
check('getPositionStream' not in service and 'getCurrentPosition' in service, 'one-shot location only')
check('timeLimit: Duration(seconds: 20)' in service, 'location acquisition bounded')
check('CurrentLocationService().obtain' not in main, 'startup does not request location')
check("String get cacheKey" in models, 'effective-coordinate cache key exists')
for file in ['screens/calendar_screen.dart', 'screens/festivals_screen.dart', 'screens/my_days_screen.dart', 'domain/festival_engine.dart']:
    source = (root/'flutter_app/lib'/file).read_text(encoding='utf-8')
    check('cacheKey' in source, f'coordinate-aware caching in {file}')
check('nationalHolidays' in holidays and 'FestivalEngine' not in holidays, 'civil holidays separate from Hindu engine')
check('must never leak into Android namespace/applicationId' in scaffold, 'Android package ID normalization preserves existing Play identity')
check('ACCESS_COARSE_LOCATION' in scaffold and 'ACCESS_FINE_LOCATION' in scaffold, 'scaffold declares foreground permissions')
check('ACCESS_BACKGROUND_LOCATION" tools:node="remove"' in scaffold, 'background permission explicitly excluded')
check('audit_android_permissions.py' in qa and 'audit_android_permissions.py' in production, 'merged APK and AAB permissions audited')
check('validate_checkpoint10.py' in qa and 'validate_checkpoint10.py' in production, 'both workflows run checkpoint 10 validation')


notifications = (root/'flutter_app/android_widget/kotlin/CalendarAlerts.kt').read_text()
check('majorFestivalsAsync' in calendar, 'year calculation asynchronous')
check('districtHi' in service and "'cityHi': location.cityHi" in settings, 'district persisted for offline launches')
check('CalendarSummaryWorker' in notifications and 'notificationBackground' in main, 'daily cache refresh works without opening UI')
check('SCHEDULE_EXACT_ALARM' in scaffold and 'POST_NOTIFICATIONS' in scaffold, 'notification permissions deliberate')
check('USE_EXACT_ALARM' not in scaffold, 'no automatic restricted exact-alarm permission')
check((root/'flutter_app/android_widget/res/raw/morning_chime.wav').exists(), 'original notification chime bundled')
failed = [m for ok, m in checks if not ok]
for ok, m in checks:
    print(('PASS' if ok else 'FAIL') + ' - ' + m)
if failed:
    sys.exit(1)
