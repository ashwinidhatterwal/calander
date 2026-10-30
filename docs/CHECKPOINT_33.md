# Build 33 — Natural Hindi, Sanatan shastra and shareable images

Version 1.0.0+33. Complete source, including all previous calendar, notification, widget, PDF, location and day-details changes.

## Discover language and focus

All 137 existing Hindi titles and reading bodies were rewritten independently in Hindi, with more natural sentences, story-led explanations and familiar expressions. Existing English readings remain available. The previous 48 teacher-specific Hindi prompts were also rewritten. Hindi references identify the texts in Hindi rather than displaying English book titles inside Hindi prose.

There are 18 additional sourced entries: nine Gita readings, three Upanishadic readings, one Taittiriya instruction, two Vedic passages and three Vivekananda reflections on patriotic service. Fifteen have verified original Sanskrit passages, clearly separated from their original Hindi bhavarth. Short extracts are identified as mantra excerpts. Vivekananda's Hindi text is explicitly a paraphrase, never an invented direct quotation. Patriotic passages concern मातृभूमि, सेवा, एकता and कर्तव्य, tied to original references.

The daily spiritual/philosophy sections now emphasize Sanatan scriptures, Bhakti, Yoga, Indian ethical teaching and service. Older Buddhist/Jain comparative entries remain in the source inventory, correctly labelled, but are excluded from the daily philosophy rotation. Four existing Gita spiritual readings now participate in the regular rotation. The three-section layout is retained; festival/tithi relevance still has priority. Total archive: 155 bilingual records.

## Share flow

Every Discover card offers **पंचांग के साथ फोटो साझा करें / Share image with Panchang**. It opens a full-screen, scrollable preview. The user can review the actual poster and then tap Share image to open Android's system chooser, including compatible messaging/social apps. The app does not post automatically.

The 1080-pixel-wide PNG includes the selected reading, original Sanskrit where applicable, teacher and source reference, Gregorian date, Vikram Samvat, Hindu month/paksha/tithi at sunrise, district/city, sunrise/sunset, nakshatra, yoga and a complete civil-day tithi sequence. All intervals are shown, including a day with three tithis. Midnight boundaries are explicitly day start/end rather than false tithi transitions. Timings use the chosen location and 12-hour Hindi/English labels. Coordinates and private events are not exported.

A branded footer contains the existing app icon, calendar promotion and the existing Play Store QR. The system-share caption also includes the Play Store link and reading source URL. The poster grows to fit measured, shaped text, independent of the phone's text scaling; no ellipsis or fixed height truncates a reading. Hindi and English are supported.

The preview and native share use identical image bytes and the same captured date/location snapshot. Repeated shares have unique filenames, preserving images still being read by another app. PNGs are shared from the existing private FileProvider cache with temporary read access; no storage permission, additional dependency or network feed is introduced. Recent shared files are retained for seven days before cleanup.

## Validation

- All 89 Flutter tests passed, including the new PNG renderer, three-tithi snapshot and exact preview-to-share byte checks. Final sharing/selection regression rerun also passed after reference/label refinements.
- Six rendered posters (Hindi/English scripture, narrative and patriotic reflection) were visually inspected, alongside Hindi/English Discover layouts and the existing narrow-screen/1.6-text-scale UI checks.
- Content rotation checks cover all 64 current section-tagged entries, excluding six archived comparative entries; teacher diversity, section separation and observance priority remain covered.
- Production-source checks and all six permission-audit tests passed.
- Native Robolectric regressions were added for Android API 28 and 35: readable PNG content URI, image MIME, caption, temporary permission, path validation and retention across repeated shares. They run in the existing GitHub build workflows.
- Flutter analysis: no issues found. All workflow YAML files parse and their shell steps pass bash syntax checks; app version and artifact labels identify build 33.
- Pure-Dart source/timeline verification passes: 155 sourced bilingual records, all 12 Hindu months, and 732 civil-day timelines including 34 triple-tithi cases.

Local validation uses Flutter 3.47.9. This environment has no Android SDK/Gradle runner; native Robolectric checks, APK/AAB compilation and the share chooser on a physical Android phone have not been run locally. GitHub has not been changed by this delivery.
