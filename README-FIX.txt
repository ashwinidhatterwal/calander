Hindu Calendar 1.0.0+19 — Compact translucent widgets

Based on build18, verified against current GitHub main f24afad.
Both widgets now request 3x1 launcher cells instead of two rows, with a 64dp
minimum height. The visible card wraps its text instead of filling unused slot
height. Daily date and lunar month share a metadata line; all data retained.
The background is 65% transparent (35% opaque) in every theme variant; all text
colours remain fully opaque. The opaque border has been removed.

Upload the complete package contents to the existing GitHub repository root.
Run Android QA build and Production Play bundle for build19. Install QA first.
REMOVE AND RE-ADD both widgets to reset existing launcher placement. They can
now be resized down to one row where the launcher supports it. The exact grid
slot size is controlled by the launcher. Check long event names, Hindi/English,
normal/larger system fonts and light/dark wallpaper before publishing.

Passed locally: source checkpoint checks, six permission-audit tests, XML parse,
compact sizing/transparency checks and scaffold shell syntax.
Android resource compiler/Flutter toolchain were unavailable for this revision;
APK/AAB compilation and actual launcher rendering remain pending in GitHub/device.
