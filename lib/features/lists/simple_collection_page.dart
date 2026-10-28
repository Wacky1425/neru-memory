import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';

class SimpleCollectionPage extends StatefulWidget{
  const SimpleCollectionPage({super.key,required this.kind,required this.title});
  final String kind,title;
  @override State<SimpleCollectionPage> createState()=>_SimpleCollectionPageState();
}
class _SimpleCollectionPageState extends State<SimpleCollectionPage>{
  DateTime weekStart=DateTime.now().subtract(Duration(days:DateTime.now().weekday-1));
  String query='';
  String get weekKey=>'${weekStart.year}-${weekStart.month.toString().padLeft(2,'0')}-${weekStart.day.toString().padLeft(2,'0')}';
  static const days=['月','火','水','木','金','土','日'];
  Future<void> edit(AppState state,[SimpleEntry? original,int day=0])async{
    final title=TextEditingController(text:original?.title??'');
    final note=TextEditingController(text:original?.note??'');
    final time=TextEditingController(text:original?.time??'');
    final category=TextEditingController(text:original?.category??'');
    int selectedDay=original?.day??day;
    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setDialog)=>AlertDialog(
      title:Text(original==null?'追加':'編集'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'タイトル'),autofocus:true),
        if(widget.kind!='weeklyEntries')TextField(controller:category,decoration:InputDecoration(labelText:widget.kind=='rememberEntries'?'カテゴリ（ゲーム・アニメなど）':'カテゴリ')),
        if(widget.kind=='weeklyEntries')...[
          DropdownButtonFormField<int>(initialValue:selectedDay,items:[for(int i=0;i<7;i++)DropdownMenuItem(value:i,child:Text('${days[i]}曜日'))],onChanged:(v)=>setDialog(()=>selectedDay=v??selectedDay)),
          TextField(controller:time,decoration:const InputDecoration(labelText:'時間（任意・例 19:00）')),
        ],
        TextField(controller:note,decoration:const InputDecoration(labelText:'メモ'),maxLines:2),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('キャンセル')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('保存'))],
    )));
    if(ok==true&&title.text.trim().isNotEmpty){
      state.saveEntry(widget.kind,SimpleEntry(id:original?.id??state.id(),title:title.text.trim(),category:category.text.trim(),note:note.text.trim(),week:original?.week??(widget.kind=='weeklyEntries'?weekKey:''),day:selectedDay,time:time.text.trim()));
    }
    title.dispose();note.dispose();time.dispose();category.dispose();
  }
  Future<void> copyPrevious(AppState state)async{
    final previous=weekStart.subtract(const Duration(days:7));
    final key='${previous.year}-${previous.month.toString().padLeft(2,'0')}-${previous.day.toString().padLeft(2,'0')}';
    final source=state.weeklyEntries.where((x)=>x.week==key).toList();
    final existing=state.weeklyEntries.where((x)=>x.week==weekKey).map((x)=>'${x.day}:${x.time}:${x.title}').toSet();
    int copied=0;
    for(final x in source){
      if(existing.contains('${x.day}:${x.time}:${x.title}'))continue;
      state.saveEntry('weeklyEntries',SimpleEntry(id:state.id(),title:x.title,note:x.note,week:weekKey,day:x.day,time:x.time));
      copied++;
    }
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${copied}件コピーしました')));
  }
  @override Widget build(BuildContext context){
    final state=AppStateScope.of(context);
    final weekly=widget.kind=='weeklyEntries';
    final all=state.entriesFor(widget.kind).where((x)=>(!weekly||x.week==weekKey)&&(query.isEmpty||'${x.title} ${x.category} ${x.note}'.toLowerCase().contains(query.toLowerCase()))).toList();
    all.sort((a,b)=>weekly?(a.day!=b.day?a.day.compareTo(b.day):a.time.compareTo(b.time)):a.category.compareTo(b.category));
    return Scaffold(appBar:AppBar(title:Text(widget.title),actions:[
      if(weekly)IconButton(tooltip:'前週をコピー',onPressed:()=>copyPrevious(state),icon:const Icon(Icons.copy_all_outlined)),
    ]),floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(state),icon:const Icon(Icons.add),label:const Text('追加')),
    body:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
      if(weekly)Row(children:[
        IconButton(onPressed:()=>setState(()=>weekStart=weekStart.subtract(const Duration(days:7))),icon:const Icon(Icons.chevron_left)),
        Expanded(child:Text('${weekStart.month}/${weekStart.day} からの1週間',textAlign:TextAlign.center)),
        IconButton(onPressed:()=>setState(()=>weekStart=weekStart.add(const Duration(days:7))),icon:const Icon(Icons.chevron_right)),
      ])else TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'検索'),onChanged:(v)=>setState(()=>query=v)),
      if(weekly)...[
        for(int day=0;day<7;day++)...[
          Padding(padding:const EdgeInsets.only(top:12,bottom:4),child:Row(children:[
            Expanded(child:Text('${days[day]}曜日',style:Theme.of(context).textTheme.titleMedium)),
            IconButton(onPressed:()=>edit(state,null,day),icon:const Icon(Icons.add_circle_outline)),
          ])),
          for(final x in all.where((e)=>e.day==day))_entry(state,x,weekly),
        ],
      ]else...[
        const SizedBox(height:12),
        if(all.isEmpty)const ListTile(title:Text('まだ登録がありません')),
        for(final x in all)_entry(state,x,weekly),
      ],
    ]));
  }
  Widget _entry(AppState state,SimpleEntry x,bool weekly)=>Card(child:ListTile(
    title:Text(x.title),
    subtitle:Text([if(weekly&&x.time.isNotEmpty)x.time,if(!weekly&&x.category.isNotEmpty)x.category,if(x.note.isNotEmpty)x.note].join(' · ')),
    onTap:()=>edit(state,x),
    trailing:IconButton(tooltip:'削除',icon:const Icon(Icons.delete_outline),onPressed:()async{
      final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('削除しますか？'),actions:[
        TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('キャンセル')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('削除')),
      ]));
      if(yes==true)state.removeEntry(widget.kind,x);
    }),
  ));
}
