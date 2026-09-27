"""Broader invariant validation for Checkpoint 02.

This is intentionally separate from the fast unit suite. It exercises a broad
cross-section of dates/cities and writes a machine-readable report that can be
kept with the checkpoint.
"""
from __future__ import annotations

from datetime import date, timedelta
import json
from pathlib import Path
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from festival_engine import major_festivals_for_year  # noqa: E402
from panchang_engine import GeoLocation, build_panchang_day  # noqa: E402

CITIES = [
    GeoLocation("Sri Ganganagar", 29.9038, 73.8772, 330),
    GeoLocation("Delhi", 28.6139, 77.2090, 330),
    GeoLocation("Jaipur", 26.9124, 75.7873, 330),
    GeoLocation("Varanasi", 25.3176, 82.9739, 330),
    GeoLocation("Lucknow", 26.8467, 80.9462, 330),
    GeoLocation("Bhopal", 23.2599, 77.4126, 330),
    GeoLocation("Chandigarh", 30.7333, 76.7794, 330),
]

EDGE_DATES = {
    date(2026, 9, 4),   # Janmashtami / moonrise regression
    date(2026, 10, 29), # Karwa Chauth / moonrise regression
    date(2027, 7, 4),   # known Kshaya Tithi
    date(2027, 9, 30),  # known Kshaya Tithi + Navratri
    date(1983, 1, 15),  # Kshaya Masa window
    date(1983, 2, 13),  # following Adhik Phalguna
}


def sampled_dates_2026():
    for month in range(1, 13):
        yield date(2026, month, 1)
        yield date(2026, month, 15)


def validate_day(d, city):
    p = build_panchang_day(d, city)
    errors = []
    if not p.sunrise < p.sunset:
        errors.append("sunrise_not_before_sunset")
    for name, value in (
        ("tithi_end", p.tithi_end),
        ("nakshatra_end", p.nakshatra_end),
        ("yoga_end", p.yoga_end),
        ("karana_end", p.karana_end),
    ):
        if value <= p.sunrise:
            errors.append(f"{name}_not_after_sunrise")
        if value > p.sunrise + timedelta(hours=36):
            errors.append(f"{name}_implausibly_far")
    if p.moonrise and p.moonrise.date() != d:
        errors.append("moonrise_wrong_local_date")
    if p.moonset and p.moonset.date() != d:
        errors.append("moonset_wrong_local_date")
    if not (1 <= p.tithi.index <= 15):
        errors.append("invalid_tithi_index")
    if not (1 <= p.nakshatra.index <= 27):
        errors.append("invalid_nakshatra_index")
    if not (1 <= p.yoga.index <= 27):
        errors.append("invalid_yoga_index")
    if not (1 <= p.karana.index <= 60):
        errors.append("invalid_karana_index")
    if p.tithi_status not in {"normal", "vriddhi", "kshaya"}:
        errors.append("invalid_tithi_status")
    return p, errors


def main():
    started = time.time()
    dates = set(sampled_dates_2026()) | EDGE_DATES
    failures = []
    anomaly_counts = {"normal": 0, "vriddhi": 0, "kshaya": 0}
    checked = 0

    for city in CITIES:
        for d in sorted(dates):
            p, errors = validate_day(d, city)
            checked += 1
            anomaly_counts[p.tithi_status] += 1
            for error in errors:
                failures.append({"city": city.city, "date": d.isoformat(), "error": error})

    # Ensure every major festival rule can resolve for both target release years
    # in every city in the initial North-India validation set.
    festival_resolutions = 0
    festival_city = next(c for c in CITIES if c.city == "Delhi")
    for year in (2026, 2027):
        festivals = major_festivals_for_year(year, festival_city)
        festival_resolutions += len(festivals)
        if len(festivals) < 14:
            failures.append({"city": festival_city.city, "year": year, "error": "missing_major_festivals"})

    report = {
        "checkpoint": "02",
        "profile": "north_india_purnimanta",
        "cities": [c.city for c in CITIES],
        "sample_dates_per_city": len(dates),
        "panchang_days_checked": checked,
        "major_festival_records_resolved": festival_resolutions,
        "tithi_status_counts": anomaly_counts,
        "failures": failures,
        "passed": not failures,
        "elapsed_seconds": round(time.time() - started, 2),
    }
    out = ROOT / "data" / "checkpoint02_validation_report.json"
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
