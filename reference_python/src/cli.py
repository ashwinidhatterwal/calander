from datetime import date
import argparse
import json

from panchang_engine import GeoLocation, build_panchang_day


def main() -> None:
    p = argparse.ArgumentParser(description="Generate a Hindu Panchang day")
    p.add_argument("date", help="YYYY-MM-DD")
    p.add_argument("--city", default="Sri Ganganagar")
    p.add_argument("--lat", type=float, default=29.9038)
    p.add_argument("--lon", type=float, default=73.8772)
    p.add_argument("--offset", type=int, default=330, help="UTC offset in minutes")
    args = p.parse_args()

    y, m, d = map(int, args.date.split("-"))
    loc = GeoLocation(args.city, args.lat, args.lon, args.offset)
    day = build_panchang_day(date(y, m, d), loc)
    print(json.dumps(day.to_dict(), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
