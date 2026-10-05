# CI17-01: legacy notification expectation

Failed QA run 37294407964, job 111712123144, source a584bb30d0473ef881bf167c480f1966568ee7f6.
Flutter analyze passed. Flutter tests: 57 passed, 1 failed. The historical
checkpoint10 test still expected Gregorian date as title after build17
intentionally promoted tithi to title. Actual: Shukla Paksha Dwitiya.

Updated that assertion to verify tithi title, explicit date, festival-first
body/date-last body, and personal event preservation. No app, native delivery,
festival selection, permission or signing behavior changed.

Local standalone Dart execution reproduces the exact November 11 payload,
including the personal event. Source checks and archive integrity passed.
Full Flutter suite and native regressions must be rerun in GitHub.
