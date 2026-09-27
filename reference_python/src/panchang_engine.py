"""License-free Hindu Panchang reference engine.

Purpose
-------
This module is the reference implementation for the Hindu Calendar app.  It has
no third-party runtime dependencies.  The mobile implementation can be ported
from these equations and verified against this file's tests.

Scope in this foundation version
--------------------------------
* Solar apparent ecliptic longitude.
* Lunar apparent ecliptic longitude using the principal periodic terms.
* Lahiri/Chitrapaksha sidereal conversion (J2000 anchor + precession model).
* Tithi, Paksha, Nakshatra, Yoga, Karana.
* Amanta and North-Indian Purnimanta lunar month.
* Sunrise/sunset using the NOAA-style solar geometry method.
* Rahu Kalam, Yamaganda, Gulika, Abhijit and Brahma Muhurta.
* Transition-time search for Tithi/Nakshatra/Yoga/Karana.

The project intentionally keeps festival selection rules outside this astronomy
module so traditional rules can be reviewed independently.
"""

from __future__ import annotations

from dataclasses import dataclass, asdict
from datetime import date, datetime, timedelta, timezone
import math
from typing import Callable, Optional


# ---------------------------------------------------------------------------
# Names / localized domain values
# ---------------------------------------------------------------------------

TITHI_HI = [
    "प्रतिपदा", "द्वितीया", "तृतीया", "चतुर्थी", "पंचमी", "षष्ठी", "सप्तमी",
    "अष्टमी", "नवमी", "दशमी", "एकादशी", "द्वादशी", "त्रयोदशी", "चतुर्दशी",
]
TITHI_EN = [
    "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami", "Shashthi",
    "Saptami", "Ashtami", "Navami", "Dashami", "Ekadashi", "Dwadashi",
    "Trayodashi", "Chaturdashi",
]

NAKSHATRA_HI = [
    "अश्विनी", "भरणी", "कृत्तिका", "रोहिणी", "मृगशिरा", "आर्द्रा", "पुनर्वसु",
    "पुष्य", "आश्लेषा", "मघा", "पूर्व फाल्गुनी", "उत्तर फाल्गुनी", "हस्त", "चित्रा",
    "स्वाती", "विशाखा", "अनुराधा", "ज्येष्ठा", "मूल", "पूर्वाषाढ़ा", "उत्तराषाढ़ा",
    "श्रवण", "धनिष्ठा", "शतभिषा", "पूर्व भाद्रपद", "उत्तर भाद्रपद", "रेवती",
]
NAKSHATRA_EN = [
    "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashirsha", "Ardra",
    "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni",
    "Uttara Phalguni", "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha",
    "Jyeshtha", "Mula", "Purva Ashadha", "Uttara Ashadha", "Shravana",
    "Dhanishtha", "Shatabhisha", "Purva Bhadrapada", "Uttara Bhadrapada", "Revati",
]

YOGA_HI = [
    "विष्कम्भ", "प्रीति", "आयुष्मान", "सौभाग्य", "शोभन", "अतिगण्ड", "सुकर्मा",
    "धृति", "शूल", "गण्ड", "वृद्धि", "ध्रुव", "व्याघात", "हर्षण", "वज्र", "सिद्धि",
    "व्यतीपात", "वरीयान", "परिघ", "शिव", "सिद्ध", "साध्य", "शुभ", "शुक्ल", "ब्रह्म",
    "इन्द्र", "वैधृति",
]
YOGA_EN = [
    "Vishkambha", "Priti", "Ayushman", "Saubhagya", "Shobhana", "Atiganda",
    "Sukarma", "Dhriti", "Shula", "Ganda", "Vriddhi", "Dhruva", "Vyaghata",
    "Harshana", "Vajra", "Siddhi", "Vyatipata", "Variyana", "Parigha", "Shiva",
    "Siddha", "Sadhya", "Shubha", "Shukla", "Brahma", "Indra", "Vaidhriti",
]

MOVABLE_KARANA_HI = ["बव", "बालव", "कौलव", "तैतिल", "गर", "वणिज", "विष्टि"]
MOVABLE_KARANA_EN = ["Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti"]

MONTH_HI = [
    "चैत्र", "वैशाख", "ज्येष्ठ", "आषाढ़", "श्रावण", "भाद्रपद",
    "आश्विन", "कार्तिक", "मार्गशीर्ष", "पौष", "माघ", "फाल्गुन",
]
MONTH_EN = [
    "Chaitra", "Vaishakha", "Jyeshtha", "Ashadha", "Shravana", "Bhadrapada",
    "Ashwin", "Kartika", "Margashirsha", "Pausha", "Magha", "Phalguna",
]

RASHI_HI = ["मेष", "वृषभ", "मिथुन", "कर्क", "सिंह", "कन्या", "तुला", "वृश्चिक", "धनु", "मकर", "कुंभ", "मीन"]
RASHI_EN = ["Mesha", "Vrishabha", "Mithuna", "Karka", "Simha", "Kanya", "Tula", "Vrishchika", "Dhanu", "Makara", "Kumbha", "Meena"]

WEEKDAY_HI = ["सोमवार", "मंगलवार", "बुधवार", "गुरुवार", "शुक्रवार", "शनिवार", "रविवार"]
WEEKDAY_EN = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


# Periodic terms for lunar ecliptic longitude.
# Tuple: D multiplier, M multiplier, M' multiplier, F multiplier, longitude coefficient.
_LUNAR_L_TERMS = [
    (0, 0, 1, 0, 6288774), (2, 0, -1, 0, 1274027), (2, 0, 0, 0, 658314),
    (0, 0, 2, 0, 213618), (0, 1, 0, 0, -185116), (0, 0, 0, 2, -114332),
    (2, 0, -2, 0, 58793), (2, -1, -1, 0, 57066), (2, 0, 1, 0, 53322),
    (2, -1, 0, 0, 45758), (0, 1, -1, 0, -40923), (1, 0, 0, 0, -34720),
    (0, 1, 1, 0, -30383), (2, 0, 0, -2, 15327), (0, 0, 1, 2, -12528),
    (0, 0, 1, -2, 10980), (4, 0, -1, 0, 10675), (0, 0, 3, 0, 10034),
    (4, 0, -2, 0, 8548), (2, 1, -1, 0, -7888), (2, 1, 0, 0, -6766),
    (1, 0, -1, 0, -5163), (1, 1, 0, 0, 4987), (2, -1, 1, 0, 4036),
    (2, 0, 2, 0, 3994), (4, 0, 0, 0, 3861), (2, 0, -3, 0, 3665),
    (0, 1, -2, 0, -2689), (2, 0, -1, 2, -2602), (2, -1, -2, 0, 2390),
    (1, 0, 1, 0, -2348), (2, -2, 0, 0, 2236), (0, 1, 2, 0, -2120),
    (0, 2, 0, 0, -2069), (2, -2, -1, 0, 2048), (2, 0, 1, -2, -1773),
    (2, 0, 0, 2, -1595), (4, -1, -1, 0, 1215), (0, 0, 2, 2, -1110),
    (3, 0, -1, 0, -892), (2, 1, 1, 0, -810), (4, -1, -2, 0, 759),
    (0, 2, -1, 0, -713), (2, 2, -1, 0, -700), (2, 1, -2, 0, 691),
    (2, -1, 0, -2, 596), (4, 0, 1, 0, 549), (0, 0, 4, 0, 537),
    (4, -1, 0, 0, 520), (1, 0, -2, 0, -487), (2, 1, 0, -2, -399),
    (0, 0, 2, -2, -381), (1, 1, 1, 0, 351), (3, 0, -2, 0, -340),
    (4, 0, -3, 0, 330), (2, -1, 2, 0, 327), (0, 2, 1, 0, -323),
    (1, 1, -1, 0, 299), (2, 0, 3, 0, 294), (2, 0, -1, -2, 0),
]


@dataclass(frozen=True)
class GeoLocation:
    city: str
    latitude: float
    longitude: float
    utc_offset_minutes: int = 330
    elevation_m: float = 0.0

    @property
    def tz(self) -> timezone:
        return timezone(timedelta(minutes=self.utc_offset_minutes))


@dataclass(frozen=True)
class NamedValue:
    index: int
    hi: str
    en: str


@dataclass(frozen=True)
class TimeRange:
    start: datetime
    end: datetime


@dataclass(frozen=True)
class PanchangDay:
    local_date: date
    weekday_hi: str
    weekday_en: str
    sunrise: datetime
    sunset: datetime
    moonrise: Optional[datetime]
    moonset: Optional[datetime]
    tithi: NamedValue
    paksha_hi: str
    paksha_en: str
    tithi_end: datetime
    next_tithi: NamedValue
    nakshatra: NamedValue
    nakshatra_end: datetime
    yoga: NamedValue
    yoga_end: datetime
    karana: NamedValue
    karana_end: datetime
    amanta_month: NamedValue
    purnimanta_month: NamedValue
    adhik_month: bool
    kshaya_month_after: Optional[NamedValue]
    tithi_status: str
    skipped_tithi: Optional[NamedValue]
    vikram_samvat: int
    shaka_samvat: int
    sun_rashi: NamedValue
    moon_rashi: NamedValue
    rahu_kalam: TimeRange
    yamaganda: TimeRange
    gulika: TimeRange
    abhijit: TimeRange
    brahma_muhurta: TimeRange

    def to_dict(self) -> dict:
        def convert(value):
            if isinstance(value, datetime):
                return value.isoformat()
            if isinstance(value, date):
                return value.isoformat()
            if hasattr(value, "__dataclass_fields__"):
                return {k: convert(v) for k, v in asdict(value).items()}
            return value

        return {k: convert(v) for k, v in self.__dict__.items()}


# ---------------------------------------------------------------------------
# Basic astronomy
# ---------------------------------------------------------------------------

def _norm(deg: float) -> float:
    return deg % 360.0


def _sin(deg: float) -> float:
    return math.sin(math.radians(deg))


def _cos(deg: float) -> float:
    return math.cos(math.radians(deg))


def julian_day(utc_dt: datetime) -> float:
    """Return Julian Day for a UTC datetime.

    Naive datetimes are treated as UTC to keep the reference API easy to test.
    """
    if utc_dt.tzinfo is not None:
        utc_dt = utc_dt.astimezone(timezone.utc).replace(tzinfo=None)
    y = utc_dt.year
    m = utc_dt.month
    day = utc_dt.day + (
        utc_dt.hour
        + (utc_dt.minute + (utc_dt.second + utc_dt.microsecond / 1_000_000) / 60) / 60
    ) / 24
    if m <= 2:
        y -= 1
        m += 12
    a = math.floor(y / 100)
    b = 2 - a + math.floor(a / 4)
    return (
        math.floor(365.25 * (y + 4716))
        + math.floor(30.6001 * (m + 1))
        + day
        + b
        - 1524.5
    )


def _julian_centuries(utc_dt: datetime) -> float:
    return (julian_day(utc_dt) - 2451545.0) / 36525.0


def sun_longitude(utc_dt: datetime) -> float:
    """Approximate apparent geocentric ecliptic longitude of the Sun, degrees."""
    t = _julian_centuries(utc_dt)
    l0 = _norm(280.46646 + 36000.76983 * t + 0.0003032 * t * t)
    m = _norm(357.52911 + 35999.05029 * t - 0.0001537 * t * t)
    c = (
        (1.914602 - 0.004817 * t - 0.000014 * t * t) * _sin(m)
        + (0.019993 - 0.000101 * t) * _sin(2 * m)
        + 0.000289 * _sin(3 * m)
    )
    true_long = l0 + c
    omega = 125.04 - 1934.136 * t
    return _norm(true_long - 0.00569 - 0.00478 * _sin(omega))


def moon_longitude(utc_dt: datetime) -> float:
    """Apparent geocentric ecliptic longitude of the Moon, degrees.

    Uses the principal lunar periodic terms, sufficient for minute-level Panchang
    transition work across the modern date range targeted by the product.
    """
    t = _julian_centuries(utc_dt)
    lp = _norm(
        218.3164477
        + 481267.88123421 * t
        - 0.0015786 * t**2
        + t**3 / 538841
        - t**4 / 65194000
    )
    d = _norm(
        297.8501921
        + 445267.1114034 * t
        - 0.0018819 * t**2
        + t**3 / 545868
        - t**4 / 113065000
    )
    m = _norm(
        357.5291092
        + 35999.0502909 * t
        - 0.0001536 * t**2
        + t**3 / 24490000
    )
    mp = _norm(
        134.9633964
        + 477198.8675055 * t
        + 0.0087414 * t**2
        + t**3 / 69699
        - t**4 / 14712000
    )
    f = _norm(
        93.2720950
        + 483202.0175233 * t
        - 0.0036539 * t**2
        - t**3 / 3526000
        + t**4 / 863310000
    )
    e = 1 - 0.002516 * t - 0.0000074 * t * t

    sigma_l = 0.0
    for dm, mm, mpm, fm, coefficient in _LUNAR_L_TERMS:
        ef = 1.0
        if abs(mm) == 1:
            ef = e
        elif abs(mm) == 2:
            ef = e * e
        sigma_l += coefficient * ef * _sin(dm * d + mm * m + mpm * mp + fm * f)

    a1 = _norm(119.75 + 131.849 * t)
    a2 = _norm(53.09 + 479264.290 * t)
    sigma_l += 3958 * _sin(a1) + 1962 * _sin(lp - f) + 318 * _sin(a2)
    geometric = lp + sigma_l / 1_000_000.0

    # Compact nutation correction in longitude.
    omega = _norm(125.04 - 1934.136 * t)
    solar_mean_long = _norm(280.4665 + 36000.7698 * t)
    nutation_arcsec = (
        -17.20 * _sin(omega)
        - 1.32 * _sin(2 * solar_mean_long)
        - 0.23 * _sin(2 * lp)
        + 0.21 * _sin(2 * omega)
    )
    return _norm(geometric + nutation_arcsec / 3600.0)


def _lunar_fundamental_arguments(utc_dt: datetime) -> tuple[float, float, float, float]:
    """Return D, M, M' and F in degrees for compact lunar coordinate work."""
    t = _julian_centuries(utc_dt)
    d = _norm(
        297.8501921 + 445267.1114034 * t - 0.0018819 * t**2
        + t**3 / 545868 - t**4 / 113065000
    )
    m = _norm(
        357.5291092 + 35999.0502909 * t - 0.0001536 * t**2
        + t**3 / 24490000
    )
    mp = _norm(
        134.9633964 + 477198.8675055 * t + 0.0087414 * t**2
        + t**3 / 69699 - t**4 / 14712000
    )
    f = _norm(
        93.2720950 + 483202.0175233 * t - 0.0036539 * t**2
        - t**3 / 3526000 + t**4 / 863310000
    )
    return d, m, mp, f


def moon_ecliptic_latitude(utc_dt: datetime) -> float:
    """Approximate geocentric ecliptic latitude of the Moon in degrees."""
    d, m, mp, f = _lunar_fundamental_arguments(utc_dt)
    return (
        5.128122 * _sin(f)
        + 0.280602 * _sin(mp + f)
        + 0.277693 * _sin(mp - f)
        + 0.173237 * _sin(2 * d - f)
        + 0.055413 * _sin(2 * d - mp + f)
        + 0.046271 * _sin(2 * d - mp - f)
        + 0.032573 * _sin(2 * d + f)
        + 0.017198 * _sin(2 * mp + f)
        + 0.009267 * _sin(2 * d + mp - f)
        + 0.008823 * _sin(2 * mp - f)
        + 0.008247 * _sin(2 * d - m - f)
        + 0.004323 * _sin(2 * d - 2 * mp - f)
        + 0.004200 * _sin(2 * d + mp + f)
        + 0.003372 * _sin(f - m - 2 * d)
        + 0.002472 * _sin(2 * d + f - m - mp)
        + 0.002222 * _sin(2 * d + f - m)
        + 0.002072 * _sin(2 * d - mp - f - m)
        + 0.001877 * _sin(f - m + mp)
        + 0.001828 * _sin(4 * d - mp - f)
        - 0.001803 * _sin(f + m)
        - 0.001750 * _sin(3 * f)
        + 0.001570 * _sin(mp - m - f)
        - 0.001487 * _sin(f + d)
        - 0.001481 * _sin(f + m + mp)
        + 0.001417 * _sin(f - m - mp)
        + 0.001350 * _sin(f - m)
    )


def _mean_obliquity(utc_dt: datetime) -> float:
    t = _julian_centuries(utc_dt)
    return 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60


def moon_equatorial(utc_dt: datetime) -> tuple[float, float]:
    """Return approximate geocentric right ascension and declination in degrees."""
    lon = math.radians(moon_longitude(utc_dt))
    lat = math.radians(moon_ecliptic_latitude(utc_dt))
    eps = math.radians(_mean_obliquity(utc_dt))
    sin_dec = math.sin(lat) * math.cos(eps) + math.cos(lat) * math.sin(eps) * math.sin(lon)
    dec = math.asin(max(-1.0, min(1.0, sin_dec)))
    ra = math.atan2(
        math.sin(lon) * math.cos(eps) - math.tan(lat) * math.sin(eps),
        math.cos(lon),
    )
    return _norm(math.degrees(ra)), math.degrees(dec)


def _greenwich_sidereal_degrees(utc_dt: datetime) -> float:
    jd = julian_day(utc_dt)
    t = (jd - 2451545.0) / 36525.0
    return _norm(
        280.46061837
        + 360.98564736629 * (jd - 2451545.0)
        + 0.000387933 * t * t
        - t**3 / 38710000.0
    )


def _moon_geocentric_altitude(utc_dt: datetime, location: GeoLocation) -> float:
    ra, dec = moon_equatorial(utc_dt)
    lst = _norm(_greenwich_sidereal_degrees(utc_dt) + location.longitude)
    hour_angle = math.radians(((lst - ra + 180.0) % 360.0) - 180.0)
    lat = math.radians(location.latitude)
    dec_r = math.radians(dec)
    sin_alt = (
        math.sin(lat) * math.sin(dec_r)
        + math.cos(lat) * math.cos(dec_r) * math.cos(hour_angle)
    )
    return math.degrees(math.asin(max(-1.0, min(1.0, sin_alt))))


def moonrise_moonset(local_date: date, location: GeoLocation) -> tuple[Optional[datetime], Optional[datetime]]:
    """Return local moonrise and moonset on a civil date.

    Uses moving lunar coordinates and the standard mean geocentric Moon
    rise/set altitude (~+0.125°). The consumer app targets minute-level display;
    published city timings are retained as regression checks.
    """
    local_start = datetime(local_date.year, local_date.month, local_date.day, tzinfo=location.tz)
    utc_start = local_start.astimezone(timezone.utc).replace(tzinfo=None)
    utc_end = (local_start + timedelta(days=1)).astimezone(timezone.utc).replace(tzinfo=None)
    threshold = 0.125

    def value(t: datetime) -> float:
        return _moon_geocentric_altitude(t, location) - threshold

    events: list[tuple[str, datetime]] = []
    step = timedelta(minutes=10)
    a = utc_start
    va = value(a)
    while a < utc_end:
        b = min(a + step, utc_end)
        vb = value(b)
        crossed_up = va <= 0 < vb
        crossed_down = va >= 0 > vb
        if crossed_up or crossed_down:
            lo, hi = a, b
            for _ in range(36):
                mid = lo + (hi - lo) / 2
                vm = value(mid)
                if crossed_up:
                    if vm <= 0:
                        lo = mid
                    else:
                        hi = mid
                else:
                    if vm >= 0:
                        lo = mid
                    else:
                        hi = mid
            events.append(("rise" if crossed_up else "set", hi))
        a, va = b, vb

    rise = next((t for kind, t in events if kind == "rise"), None)
    setting = next((t for kind, t in events if kind == "set"), None)

    def localize(value_utc: Optional[datetime]) -> Optional[datetime]:
        if value_utc is None:
            return None
        return value_utc.replace(tzinfo=timezone.utc).astimezone(location.tz)

    return localize(rise), localize(setting)


def lahiri_ayanamsha(utc_dt: datetime) -> float:
    """Lahiri/Chitrapaksha ayanamsha in degrees.

    J2000 anchor 23°51'25.53" with a compact precession polynomial.  This is kept
    explicit so a future standards update can replace the model without touching
    any Panchang rules.
    """
    t = _julian_centuries(utc_dt)
    arcseconds = 23 * 3600 + 51 * 60 + 25.53 + 5028.796195 * t + 1.1054348 * t * t
    return arcseconds / 3600.0


def sidereal_sun_longitude(utc_dt: datetime) -> float:
    return _norm(sun_longitude(utc_dt) - lahiri_ayanamsha(utc_dt))


def sidereal_moon_longitude(utc_dt: datetime) -> float:
    return _norm(moon_longitude(utc_dt) - lahiri_ayanamsha(utc_dt))


def elongation(utc_dt: datetime) -> float:
    return _norm(moon_longitude(utc_dt) - sun_longitude(utc_dt))


# ---------------------------------------------------------------------------
# Panchang elements
# ---------------------------------------------------------------------------

def tithi_at(utc_dt: datetime) -> tuple[NamedValue, str, str, int]:
    raw_index = int(elongation(utc_dt) // 12.0) + 1  # 1..30
    paksha_hi = "शुक्ल पक्ष" if raw_index <= 15 else "कृष्ण पक्ष"
    paksha_en = "Shukla Paksha" if raw_index <= 15 else "Krishna Paksha"
    within = ((raw_index - 1) % 15) + 1
    if within == 15:
        if raw_index <= 15:
            value = NamedValue(within, "पूर्णिमा", "Purnima")
        else:
            value = NamedValue(within, "अमावस्या", "Amavasya")
    else:
        value = NamedValue(within, TITHI_HI[within - 1], TITHI_EN[within - 1])
    return value, paksha_hi, paksha_en, raw_index


def named_tithi_from_raw(raw_index: int) -> NamedValue:
    """Convert a raw 1..30 tithi number into its localized Paksha name."""
    if not 1 <= raw_index <= 30:
        raise ValueError("raw tithi index must be in 1..30")
    within = ((raw_index - 1) % 15) + 1
    if within == 15:
        return NamedValue(within, "पूर्णिमा", "Purnima") if raw_index <= 15 else NamedValue(within, "अमावस्या", "Amavasya")
    return NamedValue(within, TITHI_HI[within - 1], TITHI_EN[within - 1])


def nakshatra_at(utc_dt: datetime) -> NamedValue:
    index0 = int(sidereal_moon_longitude(utc_dt) // (360.0 / 27.0))
    return NamedValue(index0 + 1, NAKSHATRA_HI[index0], NAKSHATRA_EN[index0])


def yoga_at(utc_dt: datetime) -> NamedValue:
    angle = _norm(sidereal_sun_longitude(utc_dt) + sidereal_moon_longitude(utc_dt))
    index0 = int(angle // (360.0 / 27.0))
    return NamedValue(index0 + 1, YOGA_HI[index0], YOGA_EN[index0])


def karana_at(utc_dt: datetime) -> NamedValue:
    half_tithi = int(elongation(utc_dt) // 6.0)  # 0..59
    if half_tithi == 0:
        return NamedValue(1, "किंस्तुघ्न", "Kimstughna")
    if 1 <= half_tithi <= 56:
        idx = (half_tithi - 1) % 7
        return NamedValue(half_tithi + 1, MOVABLE_KARANA_HI[idx], MOVABLE_KARANA_EN[idx])
    fixed = {
        57: ("शकुनि", "Shakuni"),
        58: ("चतुष्पद", "Chatushpada"),
        59: ("नाग", "Naga"),
    }
    hi, en = fixed[half_tithi]
    return NamedValue(half_tithi + 1, hi, en)


# ---------------------------------------------------------------------------
# Transition search
# ---------------------------------------------------------------------------

def _find_next_division_transition(
    start_utc: datetime,
    metric: Callable[[datetime], float],
    divisions: int,
    max_hours: int = 60,
) -> datetime:
    width = 360.0 / divisions
    initial = int(metric(start_utc) // width)
    lo = start_utc
    scan = timedelta(hours=1)

    for _ in range(max_hours + 2):
        hi = lo + scan
        if int(metric(hi) // width) != initial:
            # One-hour bracket, then binary refinement to sub-second precision.
            for _ in range(42):
                mid = lo + (hi - lo) / 2
                if int(metric(mid) // width) == initial:
                    lo = mid
                else:
                    hi = mid
            return hi
        lo = hi
    raise RuntimeError("No transition found inside search horizon")


def next_tithi_transition(start_utc: datetime) -> datetime:
    return _find_next_division_transition(start_utc, elongation, 30)


def next_nakshatra_transition(start_utc: datetime) -> datetime:
    return _find_next_division_transition(start_utc, sidereal_moon_longitude, 27)


def _yoga_angle(utc_dt: datetime) -> float:
    return _norm(sidereal_sun_longitude(utc_dt) + sidereal_moon_longitude(utc_dt))


def next_yoga_transition(start_utc: datetime) -> datetime:
    return _find_next_division_transition(start_utc, _yoga_angle, 27)


def next_karana_transition(start_utc: datetime) -> datetime:
    return _find_next_division_transition(start_utc, elongation, 60)


# ---------------------------------------------------------------------------
# New moon / lunar month
# ---------------------------------------------------------------------------

def _find_new_moon_bracket(start_utc: datetime, direction: int) -> tuple[datetime, datetime]:
    if direction not in (-1, 1):
        raise ValueError("direction must be -1 or +1")
    step = timedelta(hours=6 * direction)
    a = start_utc
    angle_a = elongation(a)
    for _ in range(6 * 32):  # more than one synodic month
        b = a + step
        angle_b = elongation(b)
        if direction > 0:
            if angle_a > 300 and angle_b < 60:
                return a, b
        else:
            if angle_b > 300 and angle_a < 60:
                return b, a
        a, angle_a = b, angle_b
    raise RuntimeError("New moon bracket not found")


def _bisect_new_moon(before: datetime, after: datetime) -> datetime:
    # `before` lies just before wrap (elongation near 360) and `after` just after.
    lo, hi = before, after
    for _ in range(45):
        mid = lo + (hi - lo) / 2
        if elongation(mid) > 180:
            lo = mid
        else:
            hi = mid
    return hi


def previous_new_moon(start_utc: datetime) -> datetime:
    a, b = _find_new_moon_bracket(start_utc, -1)
    return _bisect_new_moon(a, b)


def next_new_moon(start_utc: datetime) -> datetime:
    a, b = _find_new_moon_bracket(start_utc, 1)
    return _bisect_new_moon(a, b)


def lunar_month_details_at(utc_dt: datetime) -> tuple[NamedValue, NamedValue, bool, Optional[NamedValue]]:
    prev_nm = previous_new_moon(utc_dt)
    next_nm = next_new_moon(utc_dt)
    sign_prev = int(sidereal_sun_longitude(prev_nm) // 30.0)
    sign_next = int(sidereal_sun_longitude(next_nm) // 30.0)

    # Pisces new moon begins Chaitra, Aries begins Vaishakha, etc.
    amanta_idx = (sign_prev + 1) % 12
    adhik = sign_prev == sign_next
    amanta = NamedValue(amanta_idx + 1, MONTH_HI[amanta_idx], MONTH_EN[amanta_idx])

    _, _, _, raw_tithi = tithi_at(utc_dt)
    # In an Adhik month, both Pakshas retain the Adhik month name in the
    # North-Indian convention used by our default product profile.  For ordinary
    # months Purnimanta advances the month name after Purnima.
    if adhik:
        p_idx = amanta_idx
    elif raw_tithi > 15:
        p_idx = (amanta_idx + 1) % 12
    else:
        p_idx = amanta_idx
    purnimanta = NamedValue(p_idx + 1, MONTH_HI[p_idx], MONTH_EN[p_idx])
    sign_advance = (sign_next - sign_prev) % 12
    kshaya = None
    if sign_advance == 2:
        skipped_idx = (amanta_idx + 1) % 12
        kshaya = NamedValue(skipped_idx + 1, MONTH_HI[skipped_idx], MONTH_EN[skipped_idx])
    return amanta, purnimanta, adhik, kshaya


def lunar_months_at(utc_dt: datetime) -> tuple[NamedValue, NamedValue, bool]:
    """Backward-compatible compact lunar month API."""
    amanta, purnimanta, adhik, _ = lunar_month_details_at(utc_dt)
    return amanta, purnimanta, adhik


def sunrise_tithi_anomaly(local_date: date, location: GeoLocation) -> tuple[str, Optional[NamedValue]]:
    """Classify the tithi progression from this sunrise to the next sunrise.

    Returns ``normal``, ``vriddhi`` (same tithi at two sunrises), or ``kshaya``
    (one tithi begins and ends between successive sunrises).  For kshaya the
    skipped tithi is returned for display/debugging.
    """
    sunrise_today, _ = sunrise_sunset(local_date, location)
    sunrise_next, _ = sunrise_sunset(local_date + timedelta(days=1), location)
    today_utc = sunrise_today.astimezone(timezone.utc).replace(tzinfo=None)
    next_utc = sunrise_next.astimezone(timezone.utc).replace(tzinfo=None)
    _, _, _, raw_today = tithi_at(today_utc)
    _, _, _, raw_next = tithi_at(next_utc)
    advance = (raw_next - raw_today) % 30
    if advance == 0:
        return "vriddhi", None
    if advance == 2:
        skipped_raw = (raw_today % 30) + 1
        return "kshaya", named_tithi_from_raw(skipped_raw)
    return "normal", None


# ---------------------------------------------------------------------------
# Era years and Rashi
# ---------------------------------------------------------------------------

def rashi_at(utc_dt: datetime) -> tuple[NamedValue, NamedValue]:
    sun_idx = int(sidereal_sun_longitude(utc_dt) // 30.0)
    moon_idx = int(sidereal_moon_longitude(utc_dt) // 30.0)
    return (
        NamedValue(sun_idx + 1, RASHI_HI[sun_idx], RASHI_EN[sun_idx]),
        NamedValue(moon_idx + 1, RASHI_HI[moon_idx], RASHI_EN[moon_idx]),
    )


def _chaitra_start_date(gregorian_year: int, location: GeoLocation) -> date:
    """Find the local civil date on which Chaitra Shukla begins for year numbering."""
    cursor = datetime(gregorian_year, 2, 15)
    nm = next_new_moon(cursor)
    for _ in range(4):
        sign = int(sidereal_sun_longitude(nm) // 30.0)
        month_idx = (sign + 1) % 12
        if month_idx == 0:  # Chaitra
            local_nm = nm.replace(tzinfo=timezone.utc).astimezone(location.tz)
            sunrise, _ = sunrise_sunset(local_nm.date(), location)
            return local_nm.date() if local_nm <= sunrise else local_nm.date() + timedelta(days=1)
        nm = next_new_moon(nm + timedelta(days=2))
    raise RuntimeError("Unable to locate Chaitra start")


def vikram_samvat_year(local_date: date, location: GeoLocation) -> int:
    start = _chaitra_start_date(local_date.year, location)
    return local_date.year + (57 if local_date >= start else 56)


def shaka_samvat_year(local_date: date) -> int:
    """Indian National Calendar/Shaka era year number."""
    y = local_date.year
    leap = (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)
    start = date(y, 3, 21 if leap else 22)
    return y - (78 if local_date >= start else 79)


# ---------------------------------------------------------------------------
# Sun rise / set and day periods
# ---------------------------------------------------------------------------

def _solar_declination_and_eqtime(jd: float) -> tuple[float, float]:
    t = (jd - 2451545.0) / 36525.0
    l0 = _norm(280.46646 + t * (36000.76983 + 0.0003032 * t))
    m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
    e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
    c = (
        _sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t))
        + _sin(2 * m) * (0.019993 - 0.000101 * t)
        + _sin(3 * m) * 0.000289
    )
    true_long = l0 + c
    omega = 125.04 - 1934.136 * t
    lambda_app = true_long - 0.00569 - 0.00478 * _sin(omega)
    epsilon0 = 23 + (26 + ((21.448 - t * (46.815 + t * (0.00059 - t * 0.001813)))) / 60) / 60
    epsilon = epsilon0 + 0.00256 * _cos(omega)
    decl = math.degrees(math.asin(_sin(epsilon) * _sin(lambda_app)))
    y = math.tan(math.radians(epsilon) / 2) ** 2
    eqtime = 4 * math.degrees(
        y * _sin(2 * l0)
        - 2 * e * _sin(m)
        + 4 * e * y * _sin(m) * _cos(2 * l0)
        - 0.5 * y * y * _sin(4 * l0)
        - 1.25 * e * e * _sin(2 * m)
    )
    return decl, eqtime


def sunrise_sunset(local_date: date, location: GeoLocation) -> tuple[datetime, datetime]:
    """Return local sunrise and sunset using apparent upper-limb zenith 90.833°."""
    utc_midnight = datetime(local_date.year, local_date.month, local_date.day)
    jd0 = julian_day(utc_midnight)

    def event_minutes(is_sunrise: bool, seed_minutes: float) -> float:
        minutes = seed_minutes
        for _ in range(3):
            decl, eqtime = _solar_declination_and_eqtime(jd0 + minutes / 1440.0)
            cos_ha = (
                _cos(90.833) / (_cos(location.latitude) * _cos(decl))
                - math.tan(math.radians(location.latitude)) * math.tan(math.radians(decl))
            )
            if cos_ha < -1 or cos_ha > 1:
                raise ValueError("Sun does not rise/set normally at this latitude/date")
            ha = math.degrees(math.acos(cos_ha))
            signed_ha = ha if is_sunrise else -ha
            minutes = 720 - 4 * (location.longitude + signed_ha) - eqtime
        return minutes

    # Midday first approximation.
    decl_mid, eq_mid = _solar_declination_and_eqtime(jd0 + 0.5)
    cos_ha_mid = (
        _cos(90.833) / (_cos(location.latitude) * _cos(decl_mid))
        - math.tan(math.radians(location.latitude)) * math.tan(math.radians(decl_mid))
    )
    ha_mid = math.degrees(math.acos(max(-1.0, min(1.0, cos_ha_mid))))
    solar_noon = 720 - 4 * location.longitude - eq_mid
    rise_min = event_minutes(True, solar_noon - 4 * ha_mid)
    set_min = event_minutes(False, solar_noon + 4 * ha_mid)

    rise_utc = utc_midnight.replace(tzinfo=timezone.utc) + timedelta(minutes=rise_min)
    set_utc = utc_midnight.replace(tzinfo=timezone.utc) + timedelta(minutes=set_min)
    return rise_utc.astimezone(location.tz), set_utc.astimezone(location.tz)


def _segment(day_start: datetime, day_end: datetime, segment_number_1based: int) -> TimeRange:
    eighth = (day_end - day_start) / 8
    start = day_start + eighth * (segment_number_1based - 1)
    return TimeRange(start, start + eighth)


def day_periods(local_date: date, sunrise: datetime, sunset: datetime) -> dict[str, TimeRange]:
    # Python weekday: Mon=0 ... Sun=6
    wd = local_date.weekday()
    # Values are 1-based daytime eighths.
    rahu = [2, 7, 5, 6, 4, 3, 8][wd]
    yama = [4, 3, 2, 1, 7, 6, 5][wd]
    gulika = [6, 5, 4, 3, 2, 1, 7][wd]

    daylight = sunset - sunrise
    solar_noon = sunrise + daylight / 2
    muhurta = daylight / 15
    abhijit = TimeRange(solar_noon - muhurta / 2, solar_noon + muhurta / 2)
    brahma = TimeRange(sunrise - timedelta(minutes=96), sunrise - timedelta(minutes=48))
    return {
        "rahu": _segment(sunrise, sunset, rahu),
        "yamaganda": _segment(sunrise, sunset, yama),
        "gulika": _segment(sunrise, sunset, gulika),
        "abhijit": abhijit,
        "brahma": brahma,
    }


# ---------------------------------------------------------------------------
# Complete day object
# ---------------------------------------------------------------------------

def build_panchang_day(local_date: date, location: GeoLocation) -> PanchangDay:
    sunrise, sunset = sunrise_sunset(local_date, location)
    moonrise, moonset = moonrise_moonset(local_date, location)
    sunrise_utc = sunrise.astimezone(timezone.utc).replace(tzinfo=None)

    tithi, paksha_hi, paksha_en, _ = tithi_at(sunrise_utc)
    tithi_end_utc = next_tithi_transition(sunrise_utc)
    next_tithi, _, _, _ = tithi_at(tithi_end_utc + timedelta(seconds=2))

    nak = nakshatra_at(sunrise_utc)
    nak_end_utc = next_nakshatra_transition(sunrise_utc)
    yoga = yoga_at(sunrise_utc)
    yoga_end_utc = next_yoga_transition(sunrise_utc)
    karana = karana_at(sunrise_utc)
    karana_end_utc = next_karana_transition(sunrise_utc)
    amanta, purnimanta, adhik, kshaya_month_after = lunar_month_details_at(sunrise_utc)
    tithi_status, skipped_tithi = sunrise_tithi_anomaly(local_date, location)
    sun_rashi, moon_rashi = rashi_at(sunrise_utc)
    vikram = vikram_samvat_year(local_date, location)
    shaka = shaka_samvat_year(local_date)
    periods = day_periods(local_date, sunrise, sunset)

    def localize(naive_utc: datetime) -> datetime:
        return naive_utc.replace(tzinfo=timezone.utc).astimezone(location.tz)

    return PanchangDay(
        local_date=local_date,
        weekday_hi=WEEKDAY_HI[local_date.weekday()],
        weekday_en=WEEKDAY_EN[local_date.weekday()],
        sunrise=sunrise,
        sunset=sunset,
        moonrise=moonrise,
        moonset=moonset,
        tithi=tithi,
        paksha_hi=paksha_hi,
        paksha_en=paksha_en,
        tithi_end=localize(tithi_end_utc),
        next_tithi=next_tithi,
        nakshatra=nak,
        nakshatra_end=localize(nak_end_utc),
        yoga=yoga,
        yoga_end=localize(yoga_end_utc),
        karana=karana,
        karana_end=localize(karana_end_utc),
        amanta_month=amanta,
        purnimanta_month=purnimanta,
        adhik_month=adhik,
        kshaya_month_after=kshaya_month_after,
        tithi_status=tithi_status,
        skipped_tithi=skipped_tithi,
        vikram_samvat=vikram,
        shaka_samvat=shaka,
        sun_rashi=sun_rashi,
        moon_rashi=moon_rashi,
        rahu_kalam=periods["rahu"],
        yamaganda=periods["yamaganda"],
        gulika=periods["gulika"],
        abhijit=periods["abhijit"],
        brahma_muhurta=periods["brahma"],
    )
