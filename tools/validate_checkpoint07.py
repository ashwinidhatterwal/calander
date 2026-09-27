#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
checks = []

def check(condition, message):
    checks.append((condition, message))

pubspec = (root/'flutter_app/pubspec.yaml').read_text(encoding='utf-8')
main = (root/'flutter_app/lib/main.dart').read_text(encoding='utf-8')
about = (root/'flutter_app/lib/screens/about_support_screen.dart').read_text(encoding='utf-8')
privacy = (root/'flutter_app/lib/screens/privacy_screen.dart').read_text(encoding='utf-8')
workflow = (root/'.github/workflows/production.yml').read_text(encoding='utf-8')

check('version: 1.0.0+7' in pubspec, 'release version is 1.0.0+7')
check('url_launcher:' in pubspec, 'external UPI/email launcher dependency is present')
check('themeMode: ThemeMode.system' in main, 'app follows system light/dark theme')
check('unlocks no digital feature' in about, 'support flow explicitly grants no digital benefit')
check('does not upload them to a server' in privacy, 'local-data privacy statement is present')
check('flutter build appbundle' in workflow, 'production workflow builds an Android App Bundle')
check('configure_android_signing.py' in workflow, 'production workflow configures upload-key signing')
check('--obfuscate' in workflow and '--split-debug-info' in workflow, 'production Dart symbols are separated')
check('SUPPORT_UPI_ID' in workflow and 'SUPPORT_EMAIL' in workflow, 'support configuration is injected at build time')
qa = (root/'.github/workflows/android.yml').read_text(encoding='utf-8')
check('Audit Android permissions' in qa, 'QA workflow audits sensitive Android permissions')
check('target API 36+' in qa, 'QA workflow enforces the current Play target API floor')
check((root/'store_web/privacy.html').exists(), 'public privacy-policy source is included')

failed = [m for ok,m in checks if not ok]
for ok,m in checks:
    print(('PASS' if ok else 'FAIL') + ' - ' + m)
if failed:
    sys.exit(1)
