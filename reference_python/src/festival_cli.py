from __future__ import annotations

import argparse
import json

from festival_engine import all_observances_for_year, major_festivals_for_year
from panchang_engine import GeoLocation


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Hindu festival observances")
    parser.add_argument("year", type=int)
    parser.add_argument("--city", default="Sri Ganganagar")
    parser.add_argument("--lat", type=float, default=29.9038)
    parser.add_argument("--lon", type=float, default=73.8772)
    parser.add_argument("--offset", type=int, default=330)
    parser.add_argument("--all", action="store_true", help="include recurring vratas and sankrantis")
    args = parser.parse_args()

    loc = GeoLocation(args.city, args.lat, args.lon, args.offset)
    values = all_observances_for_year(args.year, loc) if args.all else major_festivals_for_year(args.year, loc)
    print(json.dumps([v.to_dict() for v in values], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
