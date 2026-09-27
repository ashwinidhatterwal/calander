# Checkpoint 05 CI Fix 01

GitHub Actions run #5 failed during `flutter analyze` with:

`The argument type 'NamedValue' can't be assigned to the parameter type 'TithiState'.`

Cause:
- `PanchangEngine.monthCell()` intentionally returns a lightweight `NamedValue`.
- `_CalendarCellData` retained the richer `TithiState` type because the UI needs `rawIndex`
  to distinguish Purnima (15) from Amavasya (30).

Fix:
- Reconstruct `TithiState` in `CalendarScreen._cellData()` using the returned Paksha and Tithi.
- Shukla raw index = 1..15.
- Krishna raw index = 16..30.

No astronomical, Tithi, month, or festival rule calculation was changed.
