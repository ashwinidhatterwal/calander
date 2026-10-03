#!/usr/bin/env bash
set -euo pipefail

# Run from flutter_app/. Generates a fresh Android host using the active stable
# Flutter toolchain, then applies this app's native resources and hardening.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

create_args=()
if [ "${CALENDAR_SCAFFOLD_OFFLINE:-false}" = "true" ]; then
  create_args+=(--offline)
fi
flutter --suppress-analytics create "${create_args[@]}" --platforms=android --org in.hinducalendar --project-name hindu_calendar "$tmp/hindu_calendar"
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
    <!-- The app defaults to light mode, so keep native launch consistent. -->
    <color name="launch_background_color">#FFF8F1</color>
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
mkdir -p android/app/src/test/kotlin/in/hinducalendar/hindu_calendar
cp android_widget/test/*.kt android/app/src/test/kotlin/in/hinducalendar/hindu_calendar/

python - <<'PY'
from pathlib import Path
# Kotlin escapes the reserved word `in` in source packages, but those escapes
# must never leak into Android namespace/applicationId strings.
gradle = Path('android/app/build.gradle.kts')
gradle.write_text(gradle.read_text(encoding='utf-8').replace(
    '"`in`.hinducalendar.hindu_calendar"', '"in.hinducalendar.hindu_calendar"'), encoding='utf-8')

with gradle.open('a', encoding='utf-8') as output:
    output.write('\ndependencies { implementation("androidx.work:work-runtime-ktx:2.11.2"); implementation("androidx.core:core:1.13.1"); testImplementation("junit:junit:4.13.2"); testImplementation("org.robolectric:robolectric:4.17"); testImplementation("androidx.work:work-testing:2.11.2") }\n')

with gradle.open('a', encoding='utf-8') as output:
    output.write('\nandroid { testOptions { unitTests { isIncludeAndroidResources = true; all { it.jvmArgs(\"--add-opens=java.base/java.lang=ALL-UNNAMED\", \"--add-opens=java.base/java.util=ALL-UNNAMED\", \"--add-opens=java.base/java.io=ALL-UNNAMED\") } } } }\n')

path = Path('android/app/src/main/AndroidManifest.xml')
text = path.read_text(encoding='utf-8')
text = text.replace('android:taskAffinity=""', 'android:taskAffinity="in.hinducalendar.hindu_calendar"')
text = text.replace('android:launchMode="singleTask"', 'android:launchMode="singleTask" android:documentLaunchMode="never"')
# geolocator's optional foreground service is not used by this one-shot feature.
# Remove its service permissions from the merged manifest explicitly.
text = text.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
    '<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools">')
text = text.replace('    <application', '''
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" tools:node="remove" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" tools:node="remove" />
    <application''', 1)


text = text.replace('    <application', '''    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <application''', 1)

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
        <receiver android:name=".CalendarAlarmReceiver" android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.TIME_SET" />
                <action android:name="android.intent.action.TIMEZONE_CHANGED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED" />
            </intent-filter>
        </receiver>

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
