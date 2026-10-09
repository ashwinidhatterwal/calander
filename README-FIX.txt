Hindu Calendar 1.0.0+18 — Polished home-screen widgets

Upload the complete package contents to the existing GitHub repository root.
Run Android QA build and Production Play bundle; both now label build18 artifacts.
Install the QA APK before uploading the signed build18 AAB to Play.

Both widgets now centre their entire content block, including after enlargement.
Oversized decorative icon/badge removed. Padding is smaller and explicit.
Daily widget defaults to 2x2 cells, festival widget to 3x2 cells on Android 12+.
Festival title has up to three lines with automatic font fitting; Hindi font
padding protects vowel marks. Rounded warm cards have a subtle border and
matching dark/dynamic colour variants. Taps and cached calendar data retained.

After installation, remove/re-add existing widgets once so launcher grid
metadata is refreshed. Check Hindi/English, light/dark, normal/larger font,
portrait/landscape, and minimum/enlarged sizes on the actual launcher.
Resource/source/permission checks passed locally. Full APK/AAB build and
on-device visual verification could not be performed in this environment.
