import unittest
import subprocess
import tempfile
from pathlib import Path

from audit_android_permissions import audit, ALLOWED, expected_version_code


class PermissionAuditTests(unittest.TestCase):
    def test_foreground_allowlist(self):
        self.assertEqual(audit(ALLOWED), ([], []))

    def test_rejects_sensitive_permissions(self):
        for suffix in [
            'ACCESS_BACKGROUND_LOCATION',
            'FOREGROUND_SERVICE_LOCATION',
            'SCHEDULE_EXACT_ALARM',
            'USE_EXACT_ALARM',
            'CAMERA',
            'READ_CONTACTS',
            'READ_SMS',
            'MANAGE_EXTERNAL_STORAGE',
        ]:
            permission = 'android.permission.' + suffix
            self.assertIn(permission, audit(ALLOWED | {permission})[0])

    def test_requires_both_foreground_permissions(self):
        self.assertEqual(len(audit([])[1]), 4)

    def test_reads_version_code_from_pubspec(self):
        with tempfile.TemporaryDirectory() as temporary:
            pubspec = Path(temporary) / 'pubspec.yaml'
            pubspec.write_text(
                "name: demo\nversion: 1.0.0+12\n",
                encoding='utf-8',
            )
            self.assertEqual(expected_version_code(pubspec), '12')

    def test_bundle_manifest_checks_identity_and_permissions(self):
        expected = expected_version_code()
        xml = (
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android" '
            'package="in.hinducalendar.hindu_calendar" '
            f'android:versionCode="{expected}">{{}}</manifest>'
        )
        permissions = ''.join(
            f'<uses-permission android:name="android.permission.{x}" />'
            for x in [
                'ACCESS_COARSE_LOCATION',
                'ACCESS_FINE_LOCATION',
                'POST_NOTIFICATIONS',
                'RECEIVE_BOOT_COMPLETED',
            ]
        )

        with tempfile.TemporaryDirectory() as temporary:
            manifest = Path(temporary) / 'manifest.xml'
            cases = [
                (xml.format(permissions), 0),
                (
                    xml.format(permissions).replace(
                        f'versionCode="{expected}"',
                        'versionCode="999999"',
                    ),
                    1,
                ),
                (
                    xml.format(permissions).replace(
                        'package="in.hinducalendar.hindu_calendar"',
                        'package="wrong.package"',
                    ),
                    1,
                ),
                (
                    xml.format(
                        permissions
                        + '<uses-permission '
                        'android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />'
                    ),
                    1,
                ),
            ]

            for content, expected_returncode in cases:
                manifest.write_text(content, encoding='utf-8')
                result = subprocess.run(
                    [
                        'python',
                        str(Path(__file__).with_name('audit_android_permissions.py')),
                        str(manifest),
                    ],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(
                    result.returncode,
                    expected_returncode,
                    result.stderr,
                )

    def test_unknown_permissions_fail_closed(self):
        self.assertEqual(
            audit(ALLOWED | {'custom.permission.UNKNOWN'})[0],
            ['custom.permission.UNKNOWN'],
        )


if __name__ == '__main__':
    unittest.main()
