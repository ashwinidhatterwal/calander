"""Regenerate Dart parity fixtures from the frozen Python reference engine."""
from __future__ import annotations
import json
from pathlib import Path
import sys
from datetime import date

ROOT=Path(__file__).resolve().parents[1]
REF=ROOT/'reference_python'
sys.path.insert(0,str(REF/'src'))
from panchang_engine import GeoLocation, build_panchang_day  # noqa: E402
from festival_engine import major_festivals_for_year  # noqa: E402

locations={
 'sri_ganganagar':GeoLocation('Sri Ganganagar',29.9038,73.8772,330),
 'delhi':GeoLocation('Delhi',28.6139,77.2090,330),
 'jaipur':GeoLocation('Jaipur',26.9124,75.7873,330),
}
cases=[
 ('sri_ganganagar',date(2026,9,27)),('delhi',date(2026,9,4)),('delhi',date(2026,10,29)),
 ('delhi',date(2026,11,8)),('jaipur',date(2026,3,4)),('delhi',date(2027,7,4)),
 ('delhi',date(2027,9,30)),('delhi',date(2023,8,15)),('delhi',date(1983,1,15)),('delhi',date(1983,2,13)),
]
out=ROOT/'flutter_app/test/fixtures'
rows=[]
for key,d in cases:
    record=build_panchang_day(d,locations[key]).to_dict(); record['location_key']=key; rows.append(record)
(out/'panchang_reference.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
fest={str(y):[x.to_dict() for x in major_festivals_for_year(y,locations['delhi'])] for y in (2026,2027)}
(out/'festival_reference.json').write_text(json.dumps(fest,ensure_ascii=False,indent=2),encoding='utf-8')
print('Parity fixtures regenerated.')
