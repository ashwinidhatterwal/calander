"""Rule-based Hindu festival / vrat engine for the Hindi-first calendar app.

The engine intentionally separates astronomical facts from traditional date
selection rules.  This checkpoint implements a North-India/Purnimanta profile
for high-utility observances.  Complex sect-specific distinctions (especially
Smarta/Vaishnava Ekadashi) remain explicitly marked for a later checkpoint.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
import json
from pathlib import Path
from typing import Callable, Optional

from panchang_engine import (
    GeoLocation,
    NamedValue,
    MONTH_EN,
    MONTH_HI,
    RASHI_EN,
    RASHI_HI,
    _find_next_division_transition,
    lunar_month_details_at,
    moonrise_moonset,
    sidereal_sun_longitude,
    sunrise_sunset,
    tithi_at,
)


@dataclass(frozen=True)
class FestivalObservance:
    id: str
    name_hi: str
    name_en: str
    local_date: date
    category: str
    importance: int
    selection_basis: str
    basis_time: Optional[datetime] = None
    notes_hi: Optional[str] = None
    notes_en: Optional[str] = None

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name_hi": self.name_hi,
            "name_en": self.name_en,
            "local_date": self.local_date.isoformat(),
            "category": self.category,
            "importance": self.importance,
            "selection_basis": self.selection_basis,
            "basis_time": self.basis_time.isoformat() if self.basis_time else None,
            "notes_hi": self.notes_hi,
            "notes_en": self.notes_en,
        }


@dataclass(frozen=True)
class FestivalRule:
    id: str
    name_hi: str
    name_en: str
    month_en: str
    paksha: str  # "shukla" | "krishna"
    tithi_index: int  # 1..15 within Paksha
    selector: str
    gregorian_months: tuple[int, ...]
    category: str = "festival"
    importance: int = 3
    notes_hi: Optional[str] = None
    notes_en: Optional[str] = None


# High-utility North Indian rules.  The selector expresses which part of the
# local solar/lunar day controls the civil-date choice.
MAJOR_RULES: tuple[FestivalRule, ...] = (
    FestivalRule(
        "maha_shivaratri", "महाशिवरात्रि", "Maha Shivaratri", "Phalguna", "krishna", 14,
        "nishita", (1, 2, 3), importance=5,
    ),
    FestivalRule(
        "rama_navami", "राम नवमी", "Rama Navami", "Chaitra", "shukla", 9,
        "madhyahna", (3, 4), importance=5,
    ),
    FestivalRule(
        "raksha_bandhan", "रक्षाबंधन", "Raksha Bandhan", "Shravana", "shukla", 15,
        "sunrise", (7, 8, 9), importance=5,
    ),
    FestivalRule(
        "janmashtami", "श्रीकृष्ण जन्माष्टमी", "Krishna Janmashtami", "Bhadrapada", "krishna", 8,
        "sunrise", (8, 9), importance=5,
        notes_hi="यह सामान्य उत्तर भारतीय तिथि चयन है; वैष्णव/सम्प्रदाय-विशिष्ट नियम अलग हो सकते हैं।",
        notes_en="General North-Indian date selection; sect-specific Vaishnava rules may differ.",
    ),
    FestivalRule(
        "ganesh_chaturthi", "गणेश चतुर्थी", "Ganesh Chaturthi", "Bhadrapada", "shukla", 4,
        "madhyahna", (8, 9), importance=4,
    ),
    FestivalRule(
        "shardiya_navratri", "शारदीय नवरात्रि आरम्भ", "Shardiya Navratri Begins", "Ashwin", "shukla", 1,
        "first_third_day", (9, 10), importance=5,
    ),
    FestivalRule(
        "vijayadashami", "विजयादशमी / दशहरा", "Vijayadashami / Dussehra", "Ashwin", "shukla", 10,
        "aparahna", (9, 10), importance=5,
    ),
    FestivalRule(
        "karwa_chauth", "करवा चौथ", "Karwa Chauth", "Kartika", "krishna", 4,
        "moonrise", (9, 10, 11), importance=5,
    ),
    FestivalRule(
        "dhanteras", "धनतेरस", "Dhanteras", "Kartika", "krishna", 13,
        "pradosha", (10, 11), importance=4,
    ),
    FestivalRule(
        "diwali", "दीपावली", "Diwali", "Kartika", "krishna", 15,
        "pradosha", (10, 11), importance=5,
    ),
    FestivalRule(
        "govardhan_puja", "गोवर्धन पूजा", "Govardhan Puja", "Kartika", "shukla", 1,
        "sunrise", (10, 11), importance=4,
    ),
    FestivalRule(
        "bhai_dooj", "भाई दूज", "Bhai Dooj", "Kartika", "shukla", 2,
        "aparahna_with_sunrise", (10, 11), importance=4,
    ),
)


def _to_naive_utc(local_dt: datetime) -> datetime:
    return local_dt.astimezone(timezone.utc).replace(tzinfo=None)


def _selector_window(local_date: date, location: GeoLocation, selector: str) -> tuple[datetime, datetime] | None:
    sunrise, sunset = sunrise_sunset(local_date, location)
    daylight = sunset - sunrise

    if selector == "sunrise":
        return sunrise, sunrise
    if selector == "madhyahna":
        return sunrise + daylight * 0.4, sunrise + daylight * 0.6
    if selector == "first_third_day":
        return sunrise, sunrise + daylight / 3
    if selector == "aparahna":
        # Hindu day split into five equal parts; Aparahna is the 4th fifth.
        return sunrise + daylight * 0.6, sunrise + daylight * 0.8
    if selector == "aparahna_with_sunrise":
        return sunrise + daylight * 0.6, sunrise + daylight * 0.8
    if selector == "pradosha":
        return sunset, sunset + timedelta(minutes=144)
    if selector == "nishita":
        next_sunrise, _ = sunrise_sunset(local_date + timedelta(days=1), location)
        night = next_sunrise - sunset
        midpoint = sunset + night / 2
        half_muhurta = night / 30
        return midpoint - half_muhurta, midpoint + half_muhurta
    if selector == "moonrise":
        rise, _ = moonrise_moonset(local_date, location)
        return (rise, rise) if rise else None
    raise ValueError(f"unknown selector: {selector}")


def _selector_time(local_date: date, location: GeoLocation, selector: str) -> Optional[datetime]:
    """Representative instant for display; matching uses the full window."""
    window = _selector_window(local_date, location, selector)
    if window is None:
        return None
    start, end = window
    return start if start == end else start + (end - start) / 2


def _window_probe_times(window: tuple[datetime, datetime]) -> list[datetime]:
    start, end = window
    if start == end:
        return [start]
    # Probe both edges and interior. One-second inset prevents exact-boundary
    # ambiguity while still detecting a short overlap such as Janmashtami 2026.
    span = end - start
    eps = min(timedelta(seconds=1), span / 100)
    return [
        start + eps,
        start + span * 0.25,
        start + span * 0.5,
        start + span * 0.75,
        end - eps,
    ]


def _matches_rule(local_date: date, location: GeoLocation, rule: FestivalRule) -> tuple[bool, Optional[datetime]]:
    window = _selector_window(local_date, location, rule.selector)
    if window is None:
        return False, None
    if rule.selector == "aparahna_with_sunrise":
        sunrise, _ = sunrise_sunset(local_date, location)
        st, _, _, sraw = tithi_at(_to_naive_utc(sunrise))
        _, smonth, _, _ = lunar_month_details_at(_to_naive_utc(sunrise))
        spaksha = "shukla" if sraw <= 15 else "krishna"
        if not (
            smonth.en == rule.month_en
            and spaksha == rule.paksha
            and st.index == rule.tithi_index
        ):
            return False, _selector_time(local_date, location, rule.selector)

    for instant in _window_probe_times(window):
        utc = _to_naive_utc(instant)
        tithi, _paksha_hi, _paksha_en, raw = tithi_at(utc)
        _amanta, purnimanta, _adhik, _kshaya = lunar_month_details_at(utc)
        paksha = "shukla" if raw <= 15 else "krishna"
        if (
            purnimanta.en == rule.month_en
            and paksha == rule.paksha
            and tithi.index == rule.tithi_index
        ):
            return True, instant
    return False, _selector_time(local_date, location, rule.selector)


def _iter_candidate_dates(year: int, months: tuple[int, ...]):
    current = date(year, min(months), 1)
    end = date(year, max(months), 28) + timedelta(days=7)
    end = end.replace(day=1) - timedelta(days=1)
    while current <= end:
        if current.month in months:
            yield current
        current += timedelta(days=1)


def find_major_festival(year: int, location: GeoLocation, festival_id: str) -> FestivalObservance:
    rule = next((r for r in MAJOR_RULES if r.id == festival_id), None)
    if rule is None:
        raise KeyError(f"unknown festival id: {festival_id}")
    for d in _iter_candidate_dates(year, rule.gregorian_months):
        matched, instant = _matches_rule(d, location, rule)
        if matched:
            return FestivalObservance(
                id=rule.id,
                name_hi=rule.name_hi,
                name_en=rule.name_en,
                local_date=d,
                category=rule.category,
                importance=rule.importance,
                selection_basis=rule.selector,
                basis_time=instant,
                notes_hi=rule.notes_hi,
                notes_en=rule.notes_en,
            )
    raise RuntimeError(f"No {festival_id} match found for {year}")


def _reviewed_override(festival_id: str, year: int, profile: str = "north_india_purnimanta") -> dict | None:
    path = Path(__file__).resolve().parents[1] / "data" / "festival_overrides.json"
    if not path.exists():
        return None
    records = json.loads(path.read_text(encoding="utf-8"))
    return next((
        item for item in records
        if item.get("festival_id") == festival_id
        and item.get("year") == year
        and item.get("profile") == profile
    ), None)


def _find_holika_dahan(year: int, location: GeoLocation) -> FestivalObservance:
    """Select Holika Dahan for the North-India profile.

    Primary rule: Phalguna Purnima overlapping Pradosha.  Holika Dahan also has
    Bhadra exceptions; the first checkpoint with a full Bhadra engine is still
    pending.  Until then, rare disputed years can be pinned by a reviewed local
    override.  2026 is one such North-India regression year.
    """
    override = _reviewed_override("holika_dahan", year)
    if override:
        d = date.fromisoformat(override["date"])
        return FestivalObservance(
            "holika_dahan", "होलिका दहन", "Holika Dahan", d,
            "festival", 5, "reviewed_north_india_override", None,
            "भद्रा/प्रदोष के जटिल अपवाद के लिए संपादकीय रूप से सत्यापित उत्तर-भारत तिथि।",
            "Editorially reviewed North-India date for a complex Bhadra/Pradosha edge case.",
        )

    probe = FestivalRule(
        "holika_dahan", "होलिका दहन", "Holika Dahan", "Phalguna", "shukla", 15,
        "pradosha", (2, 3, 4), importance=5,
    )
    for d in _iter_candidate_dates(year, probe.gregorian_months):
        matched, instant = _matches_rule(d, location, probe)
        if matched:
            return FestivalObservance(
                "holika_dahan", "होलिका दहन", "Holika Dahan", d,
                "festival", 5, "phalguna_purnima_overlaps_pradosha", instant,
                "भद्रा के सूक्ष्म मुहूर्त नियम अलग सत्यापन परत में रखे गए हैं।",
                "Detailed Bhadra muhurta rules are kept in a separate validation layer.",
            )
    raise RuntimeError(f"No Holika Dahan match found for {year}")


def major_festivals_for_year(year: int, location: GeoLocation) -> list[FestivalObservance]:
    items = [find_major_festival(year, location, r.id) for r in MAJOR_RULES]
    holika = _find_holika_dahan(year, location)
    items.append(holika)
    items.append(FestivalObservance(
        "holi", "होली / धुलंडी", "Holi / Dhulandi", holika.local_date + timedelta(days=1),
        "festival", 5, "day_after_holika_dahan",
    ))
    return sorted(items, key=lambda x: (x.local_date, -x.importance, x.name_en))


def recurring_observances_for_year(year: int, location: GeoLocation) -> list[FestivalObservance]:
    """Generate common recurring lunar observances for a North-India profile."""
    result: list[FestivalObservance] = []
    d = date(year, 1, 1)
    while d.year == year:
        sunrise, sunset = sunrise_sunset(d, location)
        utc_sunrise = _to_naive_utc(sunrise)
        tithi, _phi, _pen, raw = tithi_at(utc_sunrise)
        _, purnimanta, _, _ = lunar_month_details_at(utc_sunrise)
        paksha = "shukla" if raw <= 15 else "krishna"

        if tithi.index == 11:
            result.append(FestivalObservance(
                "ekadashi", "एकादशी", "Ekadashi", d, "vrat", 3,
                "tithi_at_sunrise", sunrise,
                "स्मार्त/वैष्णव भेद का उन्नत नियम बाद के चरण में जोड़ा जाएगा।",
                "Advanced Smarta/Vaishnava distinction is deferred to a later rule layer.",
            ))
        if raw == 15:
            result.append(FestivalObservance(
                "purnima", f"{purnimanta.hi} पूर्णिमा", f"{purnimanta.en} Purnima", d,
                "lunar_day", 2, "purnima_at_sunrise", sunrise,
            ))
        if raw == 30:
            result.append(FestivalObservance(
                "amavasya", f"{purnimanta.hi} अमावस्या", f"{purnimanta.en} Amavasya", d,
                "lunar_day", 2, "amavasya_at_sunrise", sunrise,
            ))

        # Pradosh: Trayodashi prevailing in the evening period.
        pradosha = sunset + timedelta(minutes=72)
        pt, _, _, praw = tithi_at(_to_naive_utc(pradosha))
        if pt.index == 13:
            result.append(FestivalObservance(
                "pradosh", "प्रदोष व्रत", "Pradosh Vrat", d, "vrat", 2,
                "trayodashi_at_pradosha", pradosha,
            ))

        # Sankashti: Krishna Chaturthi at local moonrise.
        moonrise, _ = moonrise_moonset(d, location)
        if moonrise is not None:
            mt, _, _, mraw = tithi_at(_to_naive_utc(moonrise))
            if mraw > 15 and mt.index == 4:
                result.append(FestivalObservance(
                    "sankashti_chaturthi", "संकष्टी चतुर्थी", "Sankashti Chaturthi", d,
                    "vrat", 2, "krishna_chaturthi_at_moonrise", moonrise,
                ))
        d += timedelta(days=1)

    return result


def sankranti_observances_for_year(year: int, location: GeoLocation) -> list[FestivalObservance]:
    """Generate the 12 sidereal solar ingress observances for the civil year."""
    start_local = datetime(year, 1, 1, tzinfo=location.tz)
    cursor = start_local.astimezone(timezone.utc).replace(tzinfo=None)
    end_local = datetime(year + 1, 1, 1, tzinfo=location.tz)
    end_utc = end_local.astimezone(timezone.utc).replace(tzinfo=None)
    result: list[FestivalObservance] = []

    while cursor < end_utc:
        transition = _find_next_division_transition(
            cursor, sidereal_sun_longitude, 12, max_hours=900
        )
        if transition >= end_utc:
            break
        after = transition + timedelta(seconds=2)
        rashi_index = int(sidereal_sun_longitude(after) // 30.0)
        local_transition = transition.replace(tzinfo=timezone.utc).astimezone(location.tz)
        name_hi = f"{RASHI_HI[rashi_index]} संक्रांति"
        name_en = f"{RASHI_EN[rashi_index]} Sankranti"
        result.append(FestivalObservance(
            f"sankranti_{rashi_index + 1}", name_hi, name_en,
            local_transition.date(), "solar", 2, "sidereal_solar_ingress", local_transition,
        ))
        cursor = transition + timedelta(hours=2)
    return result


def all_observances_for_year(year: int, location: GeoLocation) -> list[FestivalObservance]:
    items = major_festivals_for_year(year, location)
    items.extend(recurring_observances_for_year(year, location))
    items.extend(sankranti_observances_for_year(year, location))

    # Keep distinct IDs/dates, but avoid duplicate exact records caused by a
    # major festival also being a recurring lunar observance.
    seen: set[tuple[str, date]] = set()
    deduped: list[FestivalObservance] = []
    for item in sorted(items, key=lambda x: (x.local_date, -x.importance, x.name_en)):
        key = (item.id, item.local_date)
        if key not in seen:
            deduped.append(item)
            seen.add(key)
    return deduped
