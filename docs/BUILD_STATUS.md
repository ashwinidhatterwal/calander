# Current checkpoint: 1.0.0+22

Widget layout repair, portrait PDFs with Hindu/Gregorian headers, useful daily
Panchang details and a Hindi app-download footer/QR; Hindu month transitions
and complete-week month grids.

Local analyzer, actual PDF render/QR and app layout checks pass.
Both native widget layout tests pass locally: 72 combinations on Android 9/15,
with strict text-height, row-bound and ellipsis checks. The preceding GitHub run
passed analysis and 63 Flutter tests but failed these two native tests.
The updated full GitHub suite, Android packaging and phone/launcher tests remain
pending. See CI_FIX_22_02.md and CHECKPOINT_22.md for precise coverage.
