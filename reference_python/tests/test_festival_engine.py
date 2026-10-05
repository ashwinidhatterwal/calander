from datetime import date
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from festival_engine import major_festivals_for_year, sankranti_observances_for_year  # noqa: E402
from panchang_engine import GeoLocation, build_panchang_day, moonrise_moonset  # noqa: E402

DELHI = GeoLocation("Delhi", 28.6139, 77.2090, 330)


def _validation():
    return json.loads((ROOT / "data" / "validation_cases.json").read_text(encoding="utf-8"))


def _major_map(year: int):
    return {item.id: item.local_date.isoformat() for item in major_festivals_for_year(year, DELHI)}


def test_2026_major_festivals_match_reviewed_reference_dates():
    expected = _validation()["festival_dates"]["2026"]
    actual = _major_map(2026)
    assert {k: actual[k] for k in expected} == expected


def test_2027_major_festivals_match_reviewed_reference_dates():
    expected = _validation()["festival_dates"]["2027"]
    actual = _major_map(2027)
    assert {k: actual[k] for k in expected} == expected


def _minutes(dt):
    return dt.hour * 60 + dt.minute + dt.second / 60


def test_karwa_chauth_2026_delhi_moonrise_is_close_to_published_time():
    rise, _ = moonrise_moonset(date(2026, 10, 29), DELHI)
    assert rise is not None
    assert abs(_minutes(rise) - (20 * 60 + 17)) <= 8


def test_janmashtami_2026_delhi_moonrise_is_close_to_published_time():
    rise, _ = moonrise_moonset(date(2026, 9, 4), DELHI)
    assert rise is not None
    assert abs(_minutes(rise) - (23 * 60 + 29)) <= 8


def test_known_2027_kshaya_tithi_days_are_detected():
    july = build_panchang_day(date(2027, 7, 4), DELHI)
    september = build_panchang_day(date(2027, 9, 30), DELHI)
    assert july.tithi_status == "kshaya"
    assert july.skipped_tithi is not None and july.skipped_tithi.en == "Pratipada"
    assert september.tithi_status == "kshaya"
    assert september.skipped_tithi is not None and september.skipped_tithi.en == "Pratipada"


def test_2026_makara_sankranti_is_january_14():
    items = sankranti_observances_for_year(2026, DELHI)
    makara = next(x for x in items if x.name_en == "Makara Sankranti")
    assert makara.local_date == date(2026, 1, 14)


def test_1983_kshaya_month_and_following_adhik_month_are_detected():
    jan15 = build_panchang_day(date(1983, 1, 15), DELHI)
    feb13 = build_panchang_day(date(1983, 2, 13), DELHI)
    assert jan15.kshaya_month_after is not None
    assert jan15.kshaya_month_after.en == "Magha"
    assert feb13.adhik_month is True
    assert feb13.amanta_month.en == "Phalguna"


def test_durga_ashtami_matches_dated_references_in_two_years_and_locations():
    for location in [DELHI, GeoLocation("Hanumangarh", 29.58, 74.32, 330)]:
        for year, expected in [(2026, "2026-10-19"), (2027, "2027-10-07")]:
            items = {x.id: x.local_date.isoformat() for x in major_festivals_for_year(year, location)}
            assert items["durga_ashtami"] == expected
        items = {x.id: x.local_date.isoformat() for x in major_festivals_for_year(2026, location)}
        assert items["chaitra_durga_ashtami"] == "2026-03-26"
        assert items["chaitra_navratri"] == "2026-03-19"
