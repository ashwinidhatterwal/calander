from __future__ import annotations

from collections import defaultdict
from datetime import date, timedelta
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from festival_engine import all_observances_for_year  # noqa: E402
from panchang_engine import GeoLocation, build_panchang_day  # noqa: E402


LOCATION = GeoLocation("Sri Ganganagar", 29.9038, 73.8772, 330)
START = date(2026, 8, 30)
END = date(2026, 11, 15)


def hm(value):
    return value.strftime("%H:%M") if value else None


def main() -> None:
    by_date = defaultdict(list)
    for obs in all_observances_for_year(2026, LOCATION):
        if START <= obs.local_date <= END:
            by_date[obs.local_date].append({
                "id": obs.id,
                "hi": obs.name_hi,
                "en": obs.name_en,
                "kind": obs.category,
                "importance": obs.importance,
                "basis": obs.selection_basis,
                "basis_time": hm(obs.basis_time) if obs.basis_time else None,
                "notes_hi": obs.notes_hi,
                "notes_en": obs.notes_en,
            })

    rows = {}
    d = START
    while d <= END:
        p = build_panchang_day(d, LOCATION)
        obs = sorted(by_date.get(d, []), key=lambda x: (-x["importance"], x["en"]))
        rows[d.isoformat()] = {
            "date": d.isoformat(),
            "day": d.day,
            "weekday_hi": p.weekday_hi,
            "weekday_en": p.weekday_en,
            "tithi": {"hi": p.tithi.hi, "en": p.tithi.en},
            "next_tithi": {"hi": p.next_tithi.hi, "en": p.next_tithi.en},
            "paksha": {"hi": p.paksha_hi, "en": p.paksha_en},
            "month": {"hi": p.purnimanta_month.hi, "en": p.purnimanta_month.en},
            "amanta_month": {"hi": p.amanta_month.hi, "en": p.amanta_month.en},
            "adhik": p.adhik_month,
            "kshaya_month_after": (
                {"hi": p.kshaya_month_after.hi, "en": p.kshaya_month_after.en}
                if p.kshaya_month_after else None
            ),
            "tithi_status": p.tithi_status,
            "skipped_tithi": (
                {"hi": p.skipped_tithi.hi, "en": p.skipped_tithi.en}
                if p.skipped_tithi else None
            ),
            "nakshatra": {"hi": p.nakshatra.hi, "en": p.nakshatra.en},
            "yoga": {"hi": p.yoga.hi, "en": p.yoga.en},
            "karana": {"hi": p.karana.hi, "en": p.karana.en},
            "sun_rashi": {"hi": p.sun_rashi.hi, "en": p.sun_rashi.en},
            "moon_rashi": {"hi": p.moon_rashi.hi, "en": p.moon_rashi.en},
            "vikram": p.vikram_samvat,
            "shaka": p.shaka_samvat,
            "sunrise": hm(p.sunrise),
            "sunset": hm(p.sunset),
            "moonrise": hm(p.moonrise),
            "moonset": hm(p.moonset),
            "tithi_end": hm(p.tithi_end),
            "nakshatra_end": hm(p.nakshatra_end),
            "yoga_end": hm(p.yoga_end),
            "karana_end": hm(p.karana_end),
            "rahu": f"{p.rahu_kalam.start:%H:%M}–{p.rahu_kalam.end:%H:%M}",
            "yamaganda": f"{p.yamaganda.start:%H:%M}–{p.yamaganda.end:%H:%M}",
            "gulika": f"{p.gulika.start:%H:%M}–{p.gulika.end:%H:%M}",
            "abhijit": f"{p.abhijit.start:%H:%M}–{p.abhijit.end:%H:%M}",
            "brahma": f"{p.brahma_muhurta.start:%H:%M}–{p.brahma_muhurta.end:%H:%M}",
            "observances": obs,
        }
        d += timedelta(days=1)

    target = ROOT / "prototype" / "data.js"
    target.write_text(
        "window.PANCHANG_DATA = "
        + json.dumps(rows, ensure_ascii=False, separators=(",", ":"))
        + ";\n",
        encoding="utf-8",
    )
    print(f"Generated {len(rows)} day records -> {target}")


if __name__ == "__main__":
    main()
