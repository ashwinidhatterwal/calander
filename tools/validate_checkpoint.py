from __future__ import annotations
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / 'flutter_app'
required = [
    APP/'pubspec.yaml', APP/'lib/main.dart', APP/'lib/domain/panchang_engine.dart',
    APP/'lib/domain/festival_engine.dart', APP/'lib/domain/personal_event.dart',
    APP/'lib/data/personal_event_store.dart', APP/'lib/screens/calendar_screen.dart',
    APP/'lib/screens/day_details_screen.dart', APP/'lib/screens/my_days_screen.dart',
    APP/'lib/screens/personal_event_editor_screen.dart', APP/'assets/data/festival_overrides.json',
    APP/'test/fixtures/panchang_reference.json', APP/'test/fixtures/festival_reference.json',
    ROOT/'.github/workflows/android.yml', ROOT/'reference_python/src/panchang_engine.py',
]
missing = [str(x.relative_to(ROOT)) for x in required if not x.exists()]
if missing:
    raise SystemExit('Missing required files: ' + ', '.join(missing))

pubspec = (APP/'pubspec.yaml').read_text(encoding='utf-8')
if 'version: 0.5.0+5' not in pubspec:
    raise SystemExit('Checkpoint 05 app version missing')
if 'shared_preferences:' not in pubspec:
    raise SystemExit('Local personal-event persistence dependency missing')

for f in APP.rglob('*.json'):
    json.loads(f.read_text(encoding='utf-8'))

# Product should not require a paid/commercial astronomy runtime.
combined = '\n'.join(p.read_text(encoding='utf-8') for p in APP.rglob('*.dart'))
for banned in ['SwissEph', 'Swiss Ephemeris', 'swisseph', 'http.get(', 'https://api.', 'dio.get(']:
    if banned.lower() in combined.lower():
        raise SystemExit(f'Unexpected runtime dependency marker: {banned}')

# Quick structural check: remove string literals/comments and verify paired delimiters.
def strip_strings_and_comments(text: str) -> str:
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    text = re.sub(r'//.*', '', text)
    text = re.sub(r"'''(?:.|\n)*?'''", "''", text)
    text = re.sub(r'"""(?:.|\n)*?"""', '""', text)
    text = re.sub(r"'(?:\\.|[^'\\])*'", "''", text)
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    return text

pairs = {')':'(', ']':'[', '}':'{'}
for f in APP.rglob('*.dart'):
    stack=[]
    for ch in strip_strings_and_comments(f.read_text(encoding='utf-8')):
        if ch in '([{': stack.append(ch)
        elif ch in ')]}':
            if not stack or stack.pop()!=pairs[ch]:
                raise SystemExit(f'Unbalanced delimiter in {f.relative_to(ROOT)}')
    if stack:
        raise SystemExit(f'Unclosed delimiter in {f.relative_to(ROOT)}: {stack[-8:]}')

refs = json.loads((APP/'test/fixtures/panchang_reference.json').read_text(encoding='utf-8'))
if len(refs) < 10:
    raise SystemExit('Reference parity fixture set is unexpectedly small')
fest = json.loads((APP/'test/fixtures/festival_reference.json').read_text(encoding='utf-8'))
if not {'2026','2027'} <= set(fest):
    raise SystemExit('Festival fixture years missing')

print(f'checkpoint validator: PASS ({len(list(APP.rglob("*.dart")))} Dart files, {len(refs)} Panchang parity fixtures)')
