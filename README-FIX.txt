HINDU CALENDAR — BUILD 24 COMPLETE SOURCE

PDF opening optimisation:
- Static regular/bold TrueType fonts replace the variable font and fake bold
  in PDF exports. Hindi shaping and vector text are retained.
- QR runs are merged vertically without changing their pixels or link.
- The small footer icon is decoded at 128x128 rather than 1024x1024.
- Portrait page layout, calendar calculations and app/widget UI are retained.

Upload the complete contents to the existing GitHub repository.
Run Android QA build and Production Play bundle on the same commit.
Install the new QA APK, generate a NEW monthly and yearly PDF, and open both
in the phone viewer that previously showed a blank page. Old PDF files do
not change when the app updates.
Only publish the build 24 AAB after CI passes and phone testing succeeds.
Version: 1.0.0+24. Signing secrets remain the same.

See docs/CHECKPOINT_24.md for evidence and remaining validation limits.
