#!/usr/bin/env bash
set -euo pipefail

# Run from flutter_app/. Generates a fresh Android host using the active stable
# Flutter toolchain, then applies this app's native resources and hardening.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

flutter create --platforms=android --org in.hinducalendar --project-name hindu_calendar "$tmp/hindu_calendar"
rm -rf ./android
cp -R "$tmp/hindu_calendar/android" ./android

sed -i 's/android:label="hindu_calendar"/android:label="हिन्दू कैलेंडर"/' android/app/src/main/AndroidManifest.xml
sed -i 's/android:launchMode="singleTop"/android:launchMode="singleTask"/' android/app/src/main/AndroidManifest.xml

# Production launcher icon.
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  cp "assets/branding/mipmap-${density}/ic_launcher.png" "android/app/src/main/res/mipmap-${density}/ic_launcher.png"
  cp "assets/branding/mipmap-${density}/ic_launcher_round.png" "android/app/src/main/res/mipmap-${density}/ic_launcher_round.png"
done

# Theme-aware native launch surface; Flutter immediately continues with its
# branded loading screen. This avoids a black launch frame in light or dark mode.
cat > android/app/src/main/res/values/launch_colors.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="launch_background_color">#FFF8F1</color>
</resources>
XML
mkdir -p android/app/src/main/res/values-night
cat > android/app/src/main/res/values-night/launch_colors.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="launch_background_color">#18120F</color>
</resources>
XML
cat > android/app/src/main/res/drawable/launch_background.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/launch_background_color" />
</layer-list>
XML
if [ -f android/app/src/main/res/drawable-v21/launch_background.xml ]; then
  cp android/app/src/main/res/drawable/launch_background.xml android/app/src/main/res/drawable-v21/launch_background.xml
fi

# Theme-aware home-screen widgets.
cp -R android_widget/res/. android/app/src/main/res/
kotlin_dir="android/app/src/main/kotlin/in/hinducalendar/hindu_calendar"
mkdir -p "$kotlin_dir"
cp android_widget/kotlin/*.kt "$kotlin_dir/"

python - <<'PY'
from pathlib import Path
path = Path('android/app/src/main/AndroidManifest.xml')
text = path.read_text(encoding='utf-8')

queries = '''
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="upi" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="mailto" />
        </intent>
    </queries>
'''
if '<queries>' not in text:
    text = text.replace('    <application', queries + '    <application', 1)

receivers = '''
        <receiver
            android:name=".TodayPanchangWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/widget_today_info" />
        </receiver>
        <receiver
            android:name=".UpcomingWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/widget_upcoming_info" />
        </receiver>
'''
if 'TodayPanchangWidgetProvider' not in text:
    text = text.replace('    </application>', receivers + '    </application>')
path.write_text(text, encoding='utf-8')
PY
