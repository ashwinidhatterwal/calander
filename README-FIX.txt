Hindu Calendar 1.0.0+17 — Panchang notification and Durga Ashtami

Upload this full source package to the existing GitHub repository. Run QA and
Production Play bundle on the same commit; wait for both checks to pass. Test
notifications and calendar tiles, then upload the signed build17 AAB to Play.

1. Morning reminder: tithi is the prominent title, festival/vrat names come
   first in the body, followed by date and any personal events. Hindi/English.
   Separate personal-event notification keeps its date title.
2. Missing Durga rules added: Ashwin Durga Ashtami, Chaitra Durga Ashtami,
   Chaitra Navratri start. Monthly Durgashtami excluded as requested.
   Calendar and details/notification engine now share recurring labels.
   Two simultaneous major festivals can appear in the calendar badge.
3. Launcher icon unchanged; this was a feasibility question. A tithi widget
   is recommended over daily activity-alias icon switching.

Android 9 startup compatibility from build16 is retained.
Local source/permission checks, pure-Dart domain/payload checks, and Python
festival regressions passed. Flutter UI and native integration regression
checks are included for GitHub; not run locally. Full details in docs/CHECKPOINT_17.md.

CI17-01: corrected a legacy test expecting date as title. See docs/CI_FIX_17_01.md.
