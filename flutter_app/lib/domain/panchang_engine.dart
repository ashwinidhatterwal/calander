import 'dart:math' as math;
import 'models.dart';

const _tithiHi = ['प्रतिपदा','द्वितीया','तृतीया','चतुर्थी','पंचमी','षष्ठी','सप्तमी','अष्टमी','नवमी','दशमी','एकादशी','द्वादशी','त्रयोदशी','चतुर्दशी'];
const _tithiEn = ['Pratipada','Dwitiya','Tritiya','Chaturthi','Panchami','Shashthi','Saptami','Ashtami','Navami','Dashami','Ekadashi','Dwadashi','Trayodashi','Chaturdashi'];
const _nakHi = ['अश्विनी','भरणी','कृत्तिका','रोहिणी','मृगशिरा','आर्द्रा','पुनर्वसु','पुष्य','आश्लेषा','मघा','पूर्व फाल्गुनी','उत्तर फाल्गुनी','हस्त','चित्रा','स्वाती','विशाखा','अनुराधा','ज्येष्ठा','मूल','पूर्वाषाढ़ा','उत्तराषाढ़ा','श्रवण','धनिष्ठा','शतभिषा','पूर्व भाद्रपद','उत्तर भाद्रपद','रेवती'];
const _nakEn = ['Ashwini','Bharani','Krittika','Rohini','Mrigashirsha','Ardra','Punarvasu','Pushya','Ashlesha','Magha','Purva Phalguni','Uttara Phalguni','Hasta','Chitra','Swati','Vishakha','Anuradha','Jyeshtha','Mula','Purva Ashadha','Uttara Ashadha','Shravana','Dhanishtha','Shatabhisha','Purva Bhadrapada','Uttara Bhadrapada','Revati'];
const _yogaHi = ['विष्कम्भ','प्रीति','आयुष्मान','सौभाग्य','शोभन','अतिगण्ड','सुकर्मा','धृति','शूल','गण्ड','वृद्धि','ध्रुव','व्याघात','हर्षण','वज्र','सिद्धि','व्यतीपात','वरीयान','परिघ','शिव','सिद्ध','साध्य','शुभ','शुक्ल','ब्रह्म','इन्द्र','वैधृति'];
const _yogaEn = ['Vishkambha','Priti','Ayushman','Saubhagya','Shobhana','Atiganda','Sukarma','Dhriti','Shula','Ganda','Vriddhi','Dhruva','Vyaghata','Harshana','Vajra','Siddhi','Vyatipata','Variyana','Parigha','Shiva','Siddha','Sadhya','Shubha','Shukla','Brahma','Indra','Vaidhriti'];
const _movKaranaHi = ['बव','बालव','कौलव','तैतिल','गर','वणिज','विष्टि'];
const _movKaranaEn = ['Bava','Balava','Kaulava','Taitila','Garaja','Vanija','Vishti'];
const monthHi = ['चैत्र','वैशाख','ज्येष्ठ','आषाढ़','श्रावण','भाद्रपद','आश्विन','कार्तिक','मार्गशीर्ष','पौष','माघ','फाल्गुन'];
const monthEn = ['Chaitra','Vaishakha','Jyeshtha','Ashadha','Shravana','Bhadrapada','Ashwin','Kartika','Margashirsha','Pausha','Magha','Phalguna'];
const rashiHi = ['मेष','वृषभ','मिथुन','कर्क','सिंह','कन्या','तुला','वृश्चिक','धनु','मकर','कुंभ','मीन'];
const rashiEn = ['Mesha','Vrishabha','Mithuna','Karka','Simha','Kanya','Tula','Vrishchika','Dhanu','Makara','Kumbha','Meena'];
const _weekdayHi = ['सोमवार','मंगलवार','बुधवार','गुरुवार','शुक्रवार','शनिवार','रविवार'];
const _weekdayEn = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];

const List<List<num>> _lunarLTerms = [
  [0,0,1,0,6288774],[2,0,-1,0,1274027],[2,0,0,0,658314],[0,0,2,0,213618],[0,1,0,0,-185116],[0,0,0,2,-114332],
  [2,0,-2,0,58793],[2,-1,-1,0,57066],[2,0,1,0,53322],[2,-1,0,0,45758],[0,1,-1,0,-40923],[1,0,0,0,-34720],
  [0,1,1,0,-30383],[2,0,0,-2,15327],[0,0,1,2,-12528],[0,0,1,-2,10980],[4,0,-1,0,10675],[0,0,3,0,10034],
  [4,0,-2,0,8548],[2,1,-1,0,-7888],[2,1,0,0,-6766],[1,0,-1,0,-5163],[1,1,0,0,4987],[2,-1,1,0,4036],
  [2,0,2,0,3994],[4,0,0,0,3861],[2,0,-3,0,3665],[0,1,-2,0,-2689],[2,0,-1,2,-2602],[2,-1,-2,0,2390],
  [1,0,1,0,-2348],[2,-2,0,0,2236],[0,1,2,0,-2120],[0,2,0,0,-2069],[2,-2,-1,0,2048],[2,0,1,-2,-1773],
  [2,0,0,2,-1595],[4,-1,-1,0,1215],[0,0,2,2,-1110],[3,0,-1,0,-892],[2,1,1,0,-810],[4,-1,-2,0,759],
  [0,2,-1,0,-713],[2,2,-1,0,-700],[2,1,-2,0,691],[2,-1,0,-2,596],[4,0,1,0,549],[0,0,4,0,537],
  [4,-1,0,0,520],[1,0,-2,0,-487],[2,1,0,-2,-399],[0,0,2,-2,-381],[1,1,1,0,351],[3,0,-2,0,-340],
  [4,0,-3,0,330],[2,-1,2,0,327],[0,2,1,0,-323],[1,1,-1,0,299],[2,0,3,0,294],[2,0,-1,-2,0],
];

class TithiState {
  const TithiState(this.value, this.pakshaHi, this.pakshaEn, this.rawIndex);
  final NamedValue value;
  final String pakshaHi;
  final String pakshaEn;
  final int rawIndex;
}

class MonthState {
  const MonthState(this.amanta, this.purnimanta, this.adhik, this.kshayaAfter);
  final NamedValue amanta;
  final NamedValue purnimanta;
  final bool adhik;
  final NamedValue? kshayaAfter;
}

class TithiAnomaly {
  const TithiAnomaly(this.status, this.skipped);
  final String status;
  final NamedValue? skipped;
}

class PanchangEngine {
  const PanchangEngine();

  double _norm(double d) => ((d % 360.0) + 360.0) % 360.0;
  double _sin(double d) => math.sin(d * math.pi / 180.0);
  double _cos(double d) => math.cos(d * math.pi / 180.0);
  DateTime _mid(DateTime a, DateTime b) => a.add(Duration(microseconds: b.difference(a).inMicroseconds ~/ 2));
  Duration _scale(Duration d, double factor) => Duration(microseconds: (d.inMicroseconds * factor).round());

  DateTime civilDate(int year, int month, int day) => DateTime.utc(year, month, day);
  DateTime nextCivilDay(DateTime date) => DateTime.utc(date.year, date.month, date.day).add(const Duration(days: 1));
  DateTime localWall(DateTime utc, GeoLocation loc) => utc.add(loc.offset);
  DateTime localDateOfUtc(DateTime utc, GeoLocation loc) {
    final w = localWall(utc, loc);
    return DateTime.utc(w.year, w.month, w.day);
  }
  DateTime localMidnightUtc(DateTime localDate, GeoLocation loc) => DateTime.utc(localDate.year, localDate.month, localDate.day).subtract(loc.offset);

  double julianDay(DateTime utc) {
    final u = utc.toUtc();
    var y = u.year;
    var m = u.month;
    final day = u.day + (u.hour + (u.minute + (u.second + (u.millisecond + u.microsecond / 1000.0) / 1000.0) / 60.0) / 60.0) / 24.0;
    if (m <= 2) { y -= 1; m += 12; }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floorToDouble() + (30.6001 * (m + 1)).floorToDouble() + day + b - 1524.5;
  }

  double _centuries(DateTime utc) => (julianDay(utc) - 2451545.0) / 36525.0;

  double sunLongitude(DateTime utc) {
    final t = _centuries(utc);
    final l0 = _norm(280.46646 + 36000.76983 * t + 0.0003032 * t * t);
    final m = _norm(357.52911 + 35999.05029 * t - 0.0001537 * t * t);
    final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * _sin(m) +
        (0.019993 - 0.000101 * t) * _sin(2 * m) + 0.000289 * _sin(3 * m);
    final omega = 125.04 - 1934.136 * t;
    return _norm(l0 + c - 0.00569 - 0.00478 * _sin(omega));
  }

  double moonLongitude(DateTime utc) {
    final t = _centuries(utc);
    final lp = _norm(218.3164477 + 481267.88123421 * t - 0.0015786 * t * t + t * t * t / 538841 - t*t*t*t / 65194000);
    final d = _norm(297.8501921 + 445267.1114034 * t - 0.0018819 * t * t + t * t * t / 545868 - t*t*t*t / 113065000);
    final m = _norm(357.5291092 + 35999.0502909 * t - 0.0001536 * t * t + t * t * t / 24490000);
    final mp = _norm(134.9633964 + 477198.8675055 * t + 0.0087414 * t * t + t * t * t / 69699 - t*t*t*t / 14712000);
    final f = _norm(93.2720950 + 483202.0175233 * t - 0.0036539 * t * t - t * t * t / 3526000 + t*t*t*t / 863310000);
    final e = 1 - 0.002516 * t - 0.0000074 * t * t;
    var sigma = 0.0;
    for (final term in _lunarLTerms) {
      final dm = term[0].toInt(), mm = term[1].toInt(), mpm = term[2].toInt(), fm = term[3].toInt();
      final coefficient = term[4].toDouble();
      var ef = 1.0;
      if (mm.abs() == 1) ef = e;
      if (mm.abs() == 2) ef = e * e;
      sigma += coefficient * ef * _sin(dm*d + mm*m + mpm*mp + fm*f);
    }
    final a1 = _norm(119.75 + 131.849*t), a2 = _norm(53.09 + 479264.290*t);
    sigma += 3958*_sin(a1) + 1962*_sin(lp-f) + 318*_sin(a2);
    final geometric = lp + sigma / 1000000.0;
    final omega = _norm(125.04 - 1934.136*t);
    final solarMean = _norm(280.4665 + 36000.7698*t);
    final nutArcsec = -17.20*_sin(omega) -1.32*_sin(2*solarMean) -0.23*_sin(2*lp) +0.21*_sin(2*omega);
    return _norm(geometric + nutArcsec/3600.0);
  }

  List<double> _lunarArgs(DateTime utc) {
    final t = _centuries(utc);
    return [
      _norm(297.8501921 + 445267.1114034*t -0.0018819*t*t + t*t*t/545868 - t*t*t*t/113065000),
      _norm(357.5291092 + 35999.0502909*t -0.0001536*t*t + t*t*t/24490000),
      _norm(134.9633964 + 477198.8675055*t +0.0087414*t*t + t*t*t/69699 - t*t*t*t/14712000),
      _norm(93.2720950 + 483202.0175233*t -0.0036539*t*t - t*t*t/3526000 + t*t*t*t/863310000),
    ];
  }

  double moonEclipticLatitude(DateTime utc) {
    final a = _lunarArgs(utc), d=a[0], m=a[1], mp=a[2], f=a[3];
    return 5.128122*_sin(f)+0.280602*_sin(mp+f)+0.277693*_sin(mp-f)+0.173237*_sin(2*d-f)+
      0.055413*_sin(2*d-mp+f)+0.046271*_sin(2*d-mp-f)+0.032573*_sin(2*d+f)+0.017198*_sin(2*mp+f)+
      0.009267*_sin(2*d+mp-f)+0.008823*_sin(2*mp-f)+0.008247*_sin(2*d-m-f)+0.004323*_sin(2*d-2*mp-f)+
      0.004200*_sin(2*d+mp+f)+0.003372*_sin(f-m-2*d)+0.002472*_sin(2*d+f-m-mp)+0.002222*_sin(2*d+f-m)+
      0.002072*_sin(2*d-mp-f-m)+0.001877*_sin(f-m+mp)+0.001828*_sin(4*d-mp-f)-0.001803*_sin(f+m)-
      0.001750*_sin(3*f)+0.001570*_sin(mp-m-f)-0.001487*_sin(f+d)-0.001481*_sin(f+m+mp)+0.001417*_sin(f-m-mp)+0.001350*_sin(f-m);
  }

  double _meanObliquity(DateTime utc) {
    final t = _centuries(utc);
    return 23 + (26 + (21.448 - t*(46.815 + t*(0.00059 - t*0.001813)))/60)/60;
  }

  List<double> moonEquatorial(DateTime utc) {
    final lon = moonLongitude(utc)*math.pi/180, lat=moonEclipticLatitude(utc)*math.pi/180, eps=_meanObliquity(utc)*math.pi/180;
    final sinDec = math.sin(lat)*math.cos(eps)+math.cos(lat)*math.sin(eps)*math.sin(lon);
    final dec = math.asin(sinDec.clamp(-1.0,1.0));
    final ra = math.atan2(math.sin(lon)*math.cos(eps)-math.tan(lat)*math.sin(eps), math.cos(lon));
    return [_norm(ra*180/math.pi), dec*180/math.pi];
  }

  double _gst(DateTime utc) {
    final jd=julianDay(utc), t=(jd-2451545.0)/36525.0;
    return _norm(280.46061837+360.98564736629*(jd-2451545.0)+0.000387933*t*t-t*t*t/38710000.0);
  }

  double _moonAltitude(DateTime utc, GeoLocation loc) {
    final eq=moonEquatorial(utc), ra=eq[0], dec=eq[1];
    final lst=_norm(_gst(utc)+loc.longitude);
    final h=(((lst-ra+180)%360)-180)*math.pi/180, lat=loc.latitude*math.pi/180, dr=dec*math.pi/180;
    final sa=math.sin(lat)*math.sin(dr)+math.cos(lat)*math.cos(dr)*math.cos(h);
    return math.asin(sa.clamp(-1.0,1.0))*180/math.pi;
  }

  List<DateTime?> moonriseMoonset(DateTime localDate, GeoLocation loc) {
    final start=localMidnightUtc(localDate,loc), end=start.add(const Duration(days:1));
    const threshold=0.125;
    double value(DateTime t)=>_moonAltitude(t,loc)-threshold;
    DateTime? rise,set;
    var a=start, va=value(a);
    while(a.isBefore(end)){
      var b=a.add(const Duration(minutes:10)); if(b.isAfter(end)) b=end;
      final vb=value(b); final up=va<=0&&vb>0, down=va>=0&&vb<0;
      if(up||down){
        var lo=a, hi=b;
        for(var i=0;i<36;i++){
          final mid=_mid(lo,hi), vm=value(mid);
          if(up){ if(vm<=0){lo=mid;}else{hi=mid;} } else { if(vm>=0){lo=mid;}else{hi=mid;} }
        }
        if(up && rise==null) rise=hi; if(down && set==null) set=hi;
      }
      a=b; va=vb;
    }
    return [rise,set];
  }

  double lahiriAyanamsha(DateTime utc) {
    final t=_centuries(utc);
    final arc=23*3600+51*60+25.53+5028.796195*t+1.1054348*t*t;
    return arc/3600.0;
  }
  double siderealSunLongitude(DateTime utc)=>_norm(sunLongitude(utc)-lahiriAyanamsha(utc));
  double siderealMoonLongitude(DateTime utc)=>_norm(moonLongitude(utc)-lahiriAyanamsha(utc));
  double elongation(DateTime utc)=>_norm(moonLongitude(utc)-sunLongitude(utc));

  TithiState tithiAt(DateTime utc){
    final raw=(elongation(utc)/12.0).floor()+1, within=((raw-1)%15)+1;
    final hi=raw<=15?'शुक्ल पक्ष':'कृष्ण पक्ष', en=raw<=15?'Shukla Paksha':'Krishna Paksha';
    NamedValue v;
    if(within==15){ v=raw<=15?const NamedValue(15,'पूर्णिमा','Purnima'):const NamedValue(15,'अमावस्या','Amavasya'); }
    else { v=NamedValue(within,_tithiHi[within-1],_tithiEn[within-1]); }
    return TithiState(v,hi,en,raw);
  }

  NamedValue namedTithiFromRaw(int raw){
    final within=((raw-1)%15)+1;
    if(within==15) return raw<=15?const NamedValue(15,'पूर्णिमा','Purnima'):const NamedValue(15,'अमावस्या','Amavasya');
    return NamedValue(within,_tithiHi[within-1],_tithiEn[within-1]);
  }
  NamedValue nakshatraAt(DateTime utc){final i=(siderealMoonLongitude(utc)/(360/27)).floor(); return NamedValue(i+1,_nakHi[i],_nakEn[i]);}
  NamedValue yogaAt(DateTime utc){final i=(_norm(siderealSunLongitude(utc)+siderealMoonLongitude(utc))/(360/27)).floor(); return NamedValue(i+1,_yogaHi[i],_yogaEn[i]);}
  NamedValue karanaAt(DateTime utc){
    final h=(elongation(utc)/6).floor();
    if(h==0) return const NamedValue(1,'किंस्तुघ्न','Kimstughna');
    if(h<=56){final i=(h-1)%7; return NamedValue(h+1,_movKaranaHi[i],_movKaranaEn[i]);}
    if(h==57) return const NamedValue(58,'शकुनि','Shakuni');
    if(h==58) return const NamedValue(59,'चतुष्पद','Chatushpada');
    return const NamedValue(60,'नाग','Naga');
  }

  DateTime findNextDivisionTransition(DateTime start,double Function(DateTime) metric,int divisions,{int maxHours=60}){
    final width=360.0/divisions, initial=(metric(start)/width).floor(); var lo=start;
    for(var i=0;i<maxHours+2;i++){
      var hi=lo.add(const Duration(hours:1));
      if((metric(hi)/width).floor()!=initial){
        for(var j=0;j<42;j++){final mid=_mid(lo,hi); if((metric(mid)/width).floor()==initial){lo=mid;}else{hi=mid;}}
        return hi;
      }
      lo=hi;
    }
    throw StateError('No transition in search horizon');
  }
  DateTime nextTithiTransition(DateTime s)=>findNextDivisionTransition(s,elongation,30);
  DateTime nextNakshatraTransition(DateTime s)=>findNextDivisionTransition(s,siderealMoonLongitude,27);
  double _yogaAngle(DateTime t)=>_norm(siderealSunLongitude(t)+siderealMoonLongitude(t));
  DateTime nextYogaTransition(DateTime s)=>findNextDivisionTransition(s,_yogaAngle,27);
  DateTime nextKaranaTransition(DateTime s)=>findNextDivisionTransition(s,elongation,60);

  List<DateTime> _newMoonBracket(DateTime start,int direction){
    final step=Duration(hours:6*direction); var a=start, aa=elongation(a);
    for(var i=0;i<192;i++){
      final b=a.add(step), ab=elongation(b);
      if(direction>0 && aa>300 && ab<60) return [a,b];
      if(direction<0 && ab>300 && aa<60) return [b,a];
      a=b; aa=ab;
    }
    throw StateError('New moon bracket not found');
  }
  DateTime _bisectNewMoon(DateTime before,DateTime after){var lo=before,hi=after; for(var i=0;i<45;i++){final mid=_mid(lo,hi); if(elongation(mid)>180){lo=mid;}else{hi=mid;}} return hi;}
  DateTime previousNewMoon(DateTime s){final b=_newMoonBracket(s,-1); return _bisectNewMoon(b[0],b[1]);}
  DateTime nextNewMoon(DateTime s){final b=_newMoonBracket(s,1); return _bisectNewMoon(b[0],b[1]);}

  MonthState lunarMonthDetailsAt(DateTime utc){
    final prev=previousNewMoon(utc), next=nextNewMoon(utc);
    final sp=(siderealSunLongitude(prev)/30).floor(), sn=(siderealSunLongitude(next)/30).floor();
    final a=(sp+1)%12, adhik=sp==sn, ts=tithiAt(utc);
    final p=adhik?a:(ts.rawIndex>15?(a+1)%12:a);
    NamedValue? k;
    if((sn-sp)%12==2){final sk=(a+1)%12; k=NamedValue(sk+1,monthHi[sk],monthEn[sk]);}
    return MonthState(NamedValue(a+1,monthHi[a],monthEn[a]),NamedValue(p+1,monthHi[p],monthEn[p]),adhik,k);
  }

  TithiAnomaly sunriseTithiAnomaly(DateTime date,GeoLocation loc){
    final sr=sunriseSunset(date,loc)[0], nsr=sunriseSunset(nextCivilDay(date),loc)[0];
    final a=tithiAt(sr).rawIndex,b=tithiAt(nsr).rawIndex,advance=(b-a)%30;
    if(advance==0) return const TithiAnomaly('vriddhi',null);
    if(advance==2) return TithiAnomaly('kshaya',namedTithiFromRaw((a%30)+1));
    return const TithiAnomaly('normal',null);
  }

  List<NamedValue> rashiAt(DateTime utc){
    final s=(siderealSunLongitude(utc)/30).floor(),m=(siderealMoonLongitude(utc)/30).floor();
    return [NamedValue(s+1,rashiHi[s],rashiEn[s]),NamedValue(m+1,rashiHi[m],rashiEn[m])];
  }

  DateTime _chaitraStartDate(int year,GeoLocation loc){
    var nm=nextNewMoon(DateTime.utc(year,2,15));
    for(var i=0;i<4;i++){
      final sign=(siderealSunLongitude(nm)/30).floor(), month=(sign+1)%12;
      if(month==0){final local=localDateOfUtc(nm,loc), sr=sunriseSunset(local,loc)[0]; return !nm.isAfter(sr)?local:nextCivilDay(local);}
      nm=nextNewMoon(nm.add(const Duration(days:2)));
    }
    throw StateError('Unable to locate Chaitra start');
  }
  int vikramSamvatYear(DateTime date,GeoLocation loc){final start=_chaitraStartDate(date.year,loc); return date.isBefore(start)?date.year+56:date.year+57;}
  int shakaSamvatYear(DateTime date){final y=date.year,leap=(y%4==0&&y%100!=0)||y%400==0,start=DateTime.utc(y,3,leap?21:22); return date.isBefore(start)?y-79:y-78;}

  List<double> _solarDeclEq(double jd){
    final t=(jd-2451545.0)/36525.0,l0=_norm(280.46646+t*(36000.76983+0.0003032*t)),m=357.52911+t*(35999.05029-0.0001537*t),e=0.016708634-t*(0.000042037+0.0000001267*t);
    final c=_sin(m)*(1.914602-t*(0.004817+0.000014*t))+_sin(2*m)*(0.019993-0.000101*t)+_sin(3*m)*0.000289;
    final omega=125.04-1934.136*t,lambda=l0+c-0.00569-0.00478*_sin(omega),e0=23+(26+(21.448-t*(46.815+t*(0.00059-t*0.001813)))/60)/60,eps=e0+0.00256*_cos(omega);
    final decl=math.asin(_sin(eps)*_sin(lambda))*180/math.pi,y=math.pow(math.tan(eps*math.pi/360),2).toDouble();
    final eq=4*180/math.pi*(y*_sin(2*l0)-2*e*_sin(m)+4*e*y*_sin(m)*_cos(2*l0)-0.5*y*y*_sin(4*l0)-1.25*e*e*_sin(2*m));
    return [decl,eq];
  }

  List<DateTime> sunriseSunset(DateTime localDate,GeoLocation loc){
    final midnight=DateTime.utc(localDate.year,localDate.month,localDate.day),jd0=julianDay(midnight);
    double event(bool rise,double seed){var minutes=seed; for(var i=0;i<3;i++){final x=_solarDeclEq(jd0+minutes/1440),decl=x[0],eq=x[1]; final cosHa=_cos(90.833)/(_cos(loc.latitude)*_cos(decl))-math.tan(loc.latitude*math.pi/180)*math.tan(decl*math.pi/180); final ha=math.acos(cosHa.clamp(-1.0,1.0))*180/math.pi; minutes=720-4*(loc.longitude+(rise?ha:-ha))-eq;} return minutes;}
    final mid=_solarDeclEq(jd0+0.5),decl=mid[0],eq=mid[1],cosHa=_cos(90.833)/(_cos(loc.latitude)*_cos(decl))-math.tan(loc.latitude*math.pi/180)*math.tan(decl*math.pi/180),ha=math.acos(cosHa.clamp(-1.0,1.0))*180/math.pi,noon=720-4*loc.longitude-eq;
    final rise=midnight.add(Duration(microseconds:(event(true,noon-4*ha)*60*1000000).round()));
    final set=midnight.add(Duration(microseconds:(event(false,noon+4*ha)*60*1000000).round()));
    return [rise,set];
  }

  TimeRange _segment(DateTime a,DateTime b,int n){final eighth=_scale(b.difference(a),1/8),s=a.add(_scale(eighth,(n-1).toDouble())); return TimeRange(s,s.add(eighth));}
  Map<String,TimeRange> dayPeriods(DateTime date,DateTime sunrise,DateTime sunset){
    final wd=date.weekday-1,rahu=[2,7,5,6,4,3,8][wd],yama=[4,3,2,1,7,6,5][wd],gulika=[6,5,4,3,2,1,7][wd],day= sunset.difference(sunrise),noon=sunrise.add(_scale(day,0.5)),muhurta=_scale(day,1/15);
    return {'rahu':_segment(sunrise,sunset,rahu),'yamaganda':_segment(sunrise,sunset,yama),'gulika':_segment(sunrise,sunset,gulika),'abhijit':TimeRange(noon.subtract(_scale(muhurta,0.5)),noon.add(_scale(muhurta,0.5))),'brahma':TimeRange(sunrise.subtract(const Duration(minutes:96)),sunrise.subtract(const Duration(minutes:48)))};
  }

  PanchangDay buildDay(DateTime localDate,GeoLocation loc){
    final ss=sunriseSunset(localDate,loc),sunrise=ss[0],sunset=ss[1],mm=moonriseMoonset(localDate,loc),ts=tithiAt(sunrise),tEnd=nextTithiTransition(sunrise),next=tithiAt(tEnd.add(const Duration(seconds:2))).value,nak=nakshatraAt(sunrise),nakEnd=nextNakshatraTransition(sunrise),yo=yogaAt(sunrise),yoEnd=nextYogaTransition(sunrise),kar=karanaAt(sunrise),karEnd=nextKaranaTransition(sunrise),months=lunarMonthDetailsAt(sunrise),anom=sunriseTithiAnomaly(localDate,loc),rash=rashiAt(sunrise),periods=dayPeriods(localDate,sunrise,sunset);
    return PanchangDay(localDate:DateTime.utc(localDate.year,localDate.month,localDate.day),weekdayHi:_weekdayHi[localDate.weekday-1],weekdayEn:_weekdayEn[localDate.weekday-1],sunriseUtc:sunrise,sunsetUtc:sunset,moonriseUtc:mm[0],moonsetUtc:mm[1],tithi:ts.value,pakshaHi:ts.pakshaHi,pakshaEn:ts.pakshaEn,tithiEndUtc:tEnd,nextTithi:next,nakshatra:nak,nakshatraEndUtc:nakEnd,yoga:yo,yogaEndUtc:yoEnd,karana:kar,karanaEndUtc:karEnd,amantaMonth:months.amanta,purnimantaMonth:months.purnimanta,adhikMonth:months.adhik,kshayaMonthAfter:months.kshayaAfter,tithiStatus:anom.status,skippedTithi:anom.skipped,vikramSamvat:vikramSamvatYear(localDate,loc),shakaSamvat:shakaSamvatYear(localDate),sunRashi:rash[0],moonRashi:rash[1],rahuKalam:periods['rahu']!,yamaganda:periods['yamaganda']!,gulika:periods['gulika']!,abhijit:periods['abhijit']!,brahmaMuhurta:periods['brahma']!);
  }

  /// Fast month-cell summary: no moonrise or transition searches.
  ({NamedValue tithi,String pakshaHi,String pakshaEn,NamedValue month,bool adhik}) monthCell(DateTime localDate,GeoLocation loc){
    final sunrise=sunriseSunset(localDate,loc)[0],ts=tithiAt(sunrise),month=lunarMonthDetailsAt(sunrise);
    return (tithi:ts.value,pakshaHi:ts.pakshaHi,pakshaEn:ts.pakshaEn,month:month.purnimanta,adhik:month.adhik);
  }

  String hhmm(DateTime? utc,GeoLocation loc){if(utc==null)return '—'; final w=localWall(utc,loc); return '${w.hour.toString().padLeft(2,'0')}:${w.minute.toString().padLeft(2,'0')}';}
  String time12(DateTime? utc, GeoLocation loc) {
    if (utc == null) return '—';
    final wall = localWall(utc, loc);
    final hour = wall.hour % 12 == 0 ? 12 : wall.hour % 12;
    final minute = wall.minute.toString().padLeft(2, '0');
    final period = wall.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
  String range(TimeRange r,GeoLocation loc)=>'${hhmm(r.startUtc,loc)}–${hhmm(r.endUtc,loc)}';
}
