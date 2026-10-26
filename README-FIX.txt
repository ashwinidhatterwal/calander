HINDU CALENDAR — BUILD 26 COMPLETE SOURCE

- Added annual Sharad Purnima / Kojagari, selected from the nighttime tithi.
- Dussehra remains October 20, 2026 for the North Indian profile. The card
  shows Navami at sunrise followed by Dashami, instead of hiding the change.
- Month cards, Today and PDF show the tithis occurring in the Panchang day.
  Day Details explicitly identifies the sunrise tithi and shows the sequence.
- Puja-window matching now walks exact tithi boundaries instead of sampling
  five instants, avoiding missed short overlaps.
- Targeted Karwa Chauth, Govardhan and Dhanteras missing-window fallbacks
  prevent the confirmed annual-list failures.
- Reviewed North India Janmashtami 2025 exception: August 15. Complex sect
  differences remain explicitly noted; no claim of universal tradition support.
- Existing PDF speed, widget and adaptive-grid improvements are retained.

Upload all files to the existing GitHub repository. Run QA and Production Play
bundle on the same commit. Test the QA APK on your phone and generate a NEW
PDF before publishing the build 26 AAB. Signing secrets remain unchanged.
Validation and source references: docs/CHECKPOINT_26.md.

CI import-lint correction: docs/CI_FIX_26_01.md. Commit the corrected files to
start a NEW QA run; rerunning the old commit keeps the failing imports.
