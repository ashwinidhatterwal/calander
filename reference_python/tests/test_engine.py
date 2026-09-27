from datetime import date, datetime, timedelta, timezone
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from panchang_engine import (  # noqa: E402
    GeoLocation,
    build_panchang_day,
    julian_day,
    moon_longitude,
    sun_longitude,
)


SGNR = GeoLocation("Sri Ganganagar", 29.9038, 73.8772, 330)


def minutes_after_midnight(value: datetime) -> float:
    return value.hour * 60 + value.minute + value.second / 60


def test_j2000_julian_day():
    assert abs(julian_day(datetime(2000, 1, 1, 12, 0, 0)) - 2451545.0) < 1e-9


def test_longitudes_are_normalized():
    when = datetime(2026, 9, 27, 0, 0, 0)
    assert 0 <= sun_longitude(when) < 360
    assert 0 <= moon_longitude(when) < 360


def test_2026_09_27_core_panchang():
    """Published India references agree on these Panchang elements."""
    p = build_panchang_day(date(2026, 9, 27), SGNR)
    assert p.weekday_en == "Sunday"
    assert p.paksha_en == "Krishna Paksha"
    assert p.tithi.en == "Pratipada"
    assert p.next_tithi.en == "Dwitiya"
    assert p.nakshatra.en == "Uttara Bhadrapada"
    assert p.yoga.en == "Vriddhi"
    assert p.karana.en == "Balava"
    assert p.amanta_month.en == "Bhadrapada"
    assert p.purnimanta_month.en == "Ashwin"


def test_2026_09_27_transition_times_are_in_expected_window():
    p = build_panchang_day(date(2026, 9, 27), SGNR)
    # Cross-source India references are near 20:59/21:00 for tithi,
    # 11:08/11:10 nakshatra, 11:17 yoga, and 09:43 karana.
    assert abs(minutes_after_midnight(p.tithi_end) - 21 * 60) <= 3
    assert abs(minutes_after_midnight(p.nakshatra_end) - (11 * 60 + 9)) <= 3
    assert abs(minutes_after_midnight(p.yoga_end) - (11 * 60 + 18)) <= 3
    assert abs(minutes_after_midnight(p.karana_end) - (9 * 60 + 44)) <= 3


def test_2026_09_27_sunrise_is_plausible_for_sri_ganganagar():
    p = build_panchang_day(date(2026, 9, 27), SGNR)
    assert 6 * 60 + 15 <= minutes_after_midnight(p.sunrise) <= 6 * 60 + 35
    assert 18 * 60 + 10 <= minutes_after_midnight(p.sunset) <= 18 * 60 + 35


def test_sunday_rahu_is_last_eighth_of_daylight():
    p = build_panchang_day(date(2026, 9, 27), SGNR)
    daylight = p.sunset - p.sunrise
    expected_start = p.sunrise + daylight * 7 / 8
    assert abs((p.rahu_kalam.start - expected_start).total_seconds()) < 1
    assert abs((p.rahu_kalam.end - p.sunset).total_seconds()) < 0.001


def test_adhik_shravana_2023_month_naming():
    delhi = GeoLocation("Delhi", 28.6139, 77.2090, 330)
    p = build_panchang_day(date(2023, 8, 15), delhi)
    assert p.adhik_month is True
    assert p.amanta_month.en == "Shravana"
    assert p.purnimanta_month.en == "Shravana"
    assert p.tithi.en == "Chaturdashi"
    assert p.paksha_en == "Krishna Paksha"


def test_samvat_and_rashi_2026_09_27():
    p = build_panchang_day(date(2026, 9, 27), SGNR)
    assert p.vikram_samvat == 2083
    assert p.shaka_samvat == 1948
    assert p.sun_rashi.en == "Kanya"
    assert p.moon_rashi.en == "Meena"


def test_vikram_shaka_2023_adhik_month():
    delhi = GeoLocation("Delhi", 28.6139, 77.2090, 330)
    p = build_panchang_day(date(2023, 8, 15), delhi)
    assert p.vikram_samvat == 2080
    assert p.shaka_samvat == 1945
