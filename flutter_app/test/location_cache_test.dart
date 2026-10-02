import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/domain/festival_engine.dart';
import 'package:hindu_calendar/domain/models.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';

void main() {
  test('year cache uses effective coordinates and clears only changed location', () {
    const first = GeoLocation(id: 'current', cityHi: '', cityEn: '',
        latitude: 28.6, longitude: 77.2);
    const moved = GeoLocation(id: 'current', cityHi: '', cityEn: '',
        latitude: 26.9, longitude: 75.8);
    const renamed = GeoLocation(id: 'different-name', cityHi: '', cityEn: '',
        latitude: 28.6, longitude: 77.2);
    final engine = FestivalEngine(const PanchangEngine());
    final original = engine.majorFestivalsForYear(2026, first);
    expect(identical(original, engine.majorFestivalsForYear(2026, renamed)), isTrue);
    final elsewhere = engine.majorFestivalsForYear(2026, moved);
    expect(identical(original, elsewhere), isFalse);
    engine.clearLocationCache(first);
    expect(identical(elsewhere, engine.majorFestivalsForYear(2026, moved)), isTrue);
    expect(identical(original, engine.majorFestivalsForYear(2026, first)), isFalse);
  });
}
