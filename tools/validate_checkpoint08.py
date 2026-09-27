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

check('version: 1.0.0+8' in pubspec, 'build number is 8')
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

failed = [m for ok, m in checks if not ok]
for ok, m in checks:
    print(('PASS' if ok else 'FAIL') + ' - ' + m)
if failed:
    sys.exit(1)
