#!/usr/bin/env python3
"""Fail closed against the merged release APK or AAB manifest permissions."""
import argparse
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

FOREGROUND_LOCATION = {
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
}
ALLOWED = FOREGROUND_LOCATION | {
    'android.permission.POST_NOTIFICATIONS',
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

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('manifest', help='APK permissions text or bundletool manifest XML')
    args = parser.parse_args()
    raw = Path(args.manifest).read_text()
    if raw.lstrip().startswith('<'):
        document = ET.fromstring(raw)
        if document.attrib.get('package') != 'in.hinducalendar.hindu_calendar':
            sys.exit('FAIL: Android application ID changed')
        if document.attrib.get('{http://schemas.android.com/apk/res/android}versionCode') != '11':
            sys.exit('FAIL: expected version code 11')
        permissions = [node.attrib.get('{http://schemas.android.com/apk/res/android}name', '')
                       for node in document if node.tag.split('}')[-1].startswith('uses-permission')]
    else:
        permissions = [line.strip() for line in raw.splitlines() if line.strip()]
    unexpected, missing = audit(permissions)
    for permission in sorted(set(permissions)):
        print(permission)
    if unexpected or missing:
        print(f'FAIL: unexpected={unexpected}; missing foreground location={missing}', file=sys.stderr)
        sys.exit(1)
    print('PASS: only approved permissions; both foreground location permissions present')
