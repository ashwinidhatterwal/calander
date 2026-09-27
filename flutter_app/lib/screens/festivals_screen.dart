import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../domain/festival_engine.dart';
import '../domain/models.dart';
import 'day_details_screen.dart';
import '../domain/panchang_engine.dart';

class FestivalsScreen extends StatefulWidget{
  const FestivalsScreen({super.key,required this.festival,required this.language,required this.location});
  final FestivalEngine festival; final AppLanguage language; final GeoLocation location;
  @override State<FestivalsScreen> createState()=>_FestivalsScreenState();
}
class _FestivalsScreenState extends State<FestivalsScreen>{
  int year=DateTime.now().year; Future<List<FestivalObservance>>? future; String? key;
  void _ensure(){final k='$year|${widget.location.id}';if(key!=k){key=k;future=Future.sync(()=>widget.festival.majorFestivalsForYear(year,widget.location));}}
  @override void didUpdateWidget(covariant FestivalsScreen old){super.didUpdateWidget(old);if(old.location.id!=widget.location.id)key=null;}
  @override Widget build(BuildContext context){_ensure();final l=L10n(widget.language);return Column(children:[Padding(padding:const EdgeInsets.fromLTRB(16,16,12,8),child:Row(children:[Expanded(child:Text(l.festivals,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900))),IconButton(onPressed:()=>setState((){year--;key=null;}),icon:const Icon(Icons.chevron_left)),Text('$year',style:const TextStyle(fontWeight:FontWeight.w800)),IconButton(onPressed:()=>setState((){year++;key=null;}),icon:const Icon(Icons.chevron_right))])),Expanded(child:FutureBuilder<List<FestivalObservance>>(future:future,builder:(context,snap){if(!snap.hasData)return const Center(child:CircularProgressIndicator());return ListView.separated(padding:const EdgeInsets.fromLTRB(12,4,12,24),itemCount:snap.data!.length,separatorBuilder:(_,__)=>const SizedBox(height:6),itemBuilder:(context,i){final f=snap.data![i],month=widget.language==AppLanguage.hi?monthNamesHi[f.localDate.month-1]:monthNamesEn[f.localDate.month-1];return Card(child:ListTile(leading:CircleAvatar(child:Text('${f.localDate.day}')),title:Text(l.pick(f.nameHi,f.nameEn),style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('$month ${f.localDate.year}'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>DayDetailsScreen(date:f.localDate,panchang:const PanchangEngine(),festival:widget.festival,language:widget.language,location:widget.location)))));});}))]);}
}
