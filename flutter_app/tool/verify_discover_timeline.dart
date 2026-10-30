import 'dart:io';
import 'package:hindu_calendar/data/daily_discoveries.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/domain/tithi_timeline.dart';

void require(bool value, String message) { if (!value) throw StateError(message); }
void main() {
  final entries = DailyDiscoveries.entries;
  require(entries.map((e) => e.id).toSet().length == entries.length, 'duplicate IDs');
  for (final e in entries) {
    require([e.titleHi,e.titleEn,e.bodyHi,e.bodyEn,e.source].every((s)=>s.isNotEmpty), 'missing bilingual copy');
    require(Uri.parse(e.url).scheme == 'https', 'missing source');
  }
  for (var m=1;m<=12;m++) {
    final selected=DailyDiscoveries.select(date:DateTime(2026,1,8),hinduMonth:m,rawTithi:6);
    require(selected.first.reason=='month','month $m has no content');
    require(selected.map((e)=>e.entry.id).toSet().length==selected.length,'duplicate selection');
  }
  final ranked=DailyDiscoveries.select(date:DateTime(2026,3,27),hinduMonth:1,rawTithi:3,festivals:{'rama_navami'});
  require(ranked.first.entry.id=='rama-reading','festival priority');
  require(ranked.firstWhere((e)=>e.entry.id=='gangaur').reason=='tithi','tithi priority');
  var triple=0;
  for (final location in [locations.first, locations.last]) {
    for (var i=0;i<366;i++) {
      final d=DateTime.utc(2026,1,1).add(Duration(days:i));
      final parts=civilTithiTimeline(const PanchangEngine(),d,location);
      require(parts.first.fromUtc==d.subtract(location.offset),'start boundary');
      require(parts.last.toUtc==d.add(const Duration(days:1)).subtract(location.offset),'end boundary');
      require(parts.where((p)=>p.atSunrise).length==1,'sunrise');
      for (var j=0;j<parts.length;j++) {
        require(parts[j].toUtc.isAfter(parts[j].fromUtc),'empty interval');
        if(j>0) {
          require(parts[j].fromUtc==parts[j-1].toUtc,'timeline gap');
          require(parts[j].state.rawIndex==parts[j-1].state.rawIndex%30+1,'wrong transition');
        }
      }
      if(parts.length==3) { triple++; stdout.writeln('Two transitions: ${d.toIso8601String().substring(0,10)} ${location.id}'); }
    }
  }
  require(triple>0,'no triple day exercised');
  stdout.writeln('PASS: ${entries.length} sourced bilingual records; all 12 months; priority and deduplication; 732 civil-day timelines including $triple triple-tithi cases.');
}
