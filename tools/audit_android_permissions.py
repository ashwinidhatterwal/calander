#!/usr/bin/env python3
"""Fail closed against the merged release APK or AAB manifest permissions."""
import argparse
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

FOREGROUND_LOCATION = {
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
}
ALLOWED = FOREGROUND_LOCATION | {
    'android.permission.POST_NOTIFICATIONS',
    # Optional user-granted Alarms & reminders access for selected reminder times.
    'android.permission.SCHEDULE_EXACT_ALARM',
    'android.permission.INTERNET',
    'android.permission.ACCESS_NETWORK_STATE',
    'android.permission.WAKE_LOCK',
    # Existing home_widget -> AndroidX WorkManager rescheduling receiver.
    # The app schedules no background location work.
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'in.hinducalendar.hindu_calendar.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
}

REQUIRED = FOREGROUND_LOCATION | {
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.RECEIVE_BOOT_COMPLETED',
}


def audit(permissions):
    return sorted(set(permissions) - ALLOWED), sorted(REQUIRED - set(permissions))


def expected_version_code(pubspec=None):
    """Read the Android build number from pubspec.yaml, the release source of truth."""
    path = Path(pubspec) if pubspec else Path(__file__).resolve().parents[1] / 'flutter_app' / 'pubspec.yaml'
    text = path.read_text(encoding='utf-8')
    match = re.search(r'^\s*version:\s*[^\s+]+\+(\d+)\s*$', text, re.MULTILINE)
    if not match:
        raise RuntimeError(f'Cannot determine build number from {path}')
    return match.group(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('manifest', help='APK permissions text or bundletool manifest XML')
    args = parser.parse_args()
    raw = Path(args.manifest).read_text(encoding='utf-8')

    if raw.lstrip().startswith('<'):
        document = ET.fromstring(raw)
        if document.attrib.get('package') != 'in.hinducalendar.hindu_calendar':
            sys.exit('FAIL: Android application ID changed')

        expected = expected_version_code()
        actual = document.attrib.get(
            '{http://schemas.android.com/apk/res/android}versionCode'
        )
        if actual != expected:
            sys.exit(
                f'FAIL: expected version code {expected}, got {actual or "missing"}'
            )

        permissions = [
            node.attrib.get(
                '{http://schemas.android.com/apk/res/android}name', ''
            )
            for node in document
            if node.tag.split('}')[-1].startswith('uses-permission')
        ]
    else:
        permissions = [line.strip() for line in raw.splitlines() if line.strip()]

    unexpected, missing = audit(permissions)

    for permission in sorted(set(permissions)):
        print(permission)

    if unexpected or missing:
        print(
            f'FAIL: unexpected={unexpected}; missing required permissions={missing}',
            file=sys.stderr,
        )
        sys.exit(1)

    print('PASS: release identity and approved permissions verified')
