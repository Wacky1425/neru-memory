import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/google_calendar_service.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../../widgets/date_fields.dart';
import '../lists/editors.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override State<CalendarPage> createState()=>_CalendarPageState();
}
class _CalendarPageState extends State<CalendarPage> {
  DateTime month=DateTime(DateTime.now().year,DateTime.now().month);
  DateTime selected=DateTime.now();
  List<CalendarEventItem> events=[];
  bool connected=false,busy=false; String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreCalendar();
    });
  }

  Future<void> _restoreCalendar() async {
    setState(() => busy = true);
    try {
      connected = await GoogleCalendarService.instance.restoreConnection();
      if (connected) {
        await load();
      }
    } catch (e) {
      error = friendlyError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  bool same(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month&&a.day==b.day;
  String hm(DateTime d)=>'${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  String friendlyError(Object e){
    final x='$e';
    if(x.contains('403')&&(x.contains('SERVICE_DISABLED')||x.contains('accessNotConfigured'))) return 'Google Calendar API が無効です。Google Cloudで有効化してから更新してください。';
    if(x.contains('401')) return 'Google Calendarの認証を自動更新できませんでした。接続ボタンから再認証してください。';
    if(x.contains('Calendar authorization required')) return 'Google Calendarの権限を再確認する必要があります。接続ボタンを押してください。';
    return 'Google Calendarの取得に失敗しました。右上の更新から再試行できます。';
  }
  Future<void> connect() async {
    setState(()=>busy=true);
    try { await GoogleCalendarService.instance.connect(); connected=true; await load(); }
    catch(e){ if(mounted)setState(()=>error=friendlyError(e)); }
    finally { if(mounted)setState(()=>busy=false); }
  }
  Future<void> load() async {
    if (!connected) {
      connected = await GoogleCalendarService.instance.restoreConnection();
      if (!connected) {
        if (mounted) setState(() {});
        return;
      }
    }
    if (mounted) setState(() => busy = true);
    try {
      events = await GoogleCalendarService.instance.listEvents(
        DateTime(month.year, month.month, 1),
        DateTime(month.year, month.month + 1, 1),
      );
      await _reconcileLinkedFutures();
      error = null;
    } catch (e) {
      connected = GoogleCalendarService.instance.isConnected;
      error = friendlyError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  Future<void> _reconcileLinkedFutures() async {
    if (!mounted) return;
    final state = AppStateScope.of(context);
    final linked = state.futures
        .where((future) => future.googleEventId != null)
        .toList();

    var pulledChanges = 0;
    var removedLinks = 0;
    for (final future in linked) {
      final eventId = future.googleEventId!;
      CalendarEventItem? googleEvent;
      for (final event in events) {
        if (event.id == eventId) {
          googleEvent = event;
          break;
        }
      }
      googleEvent ??= await GoogleCalendarService.instance.getEvent(eventId);

      if (googleEvent == null) {
        future.googleEventId = null;
        state.updateFuture(future);
        removedLinks++;
        continue;
      }

      final changed = future.title != googleEvent.title ||
          future.note != googleEvent.description ||
          future.scheduledAt == null ||
          future.scheduledAt!.difference(googleEvent.start).inSeconds.abs() > 1;
      if (changed) {
        future.title = googleEvent.title;
        future.note = googleEvent.description;
        future.scheduledAt = googleEvent.start;
        future.status = FutureStatus.scheduled;
        state.updateFuture(future);
        pulledChanges++;
      }
    }
    if (mounted && (pulledChanges > 0 || removedLinks > 0)) {
      final parts = <String>[
        if (pulledChanges > 0) 'Google側の変更を$pulledChanges件反映',
        if (removedLinks > 0) '削除済み予定の連携を$removedLinks件解除',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parts.join(' · '))),
      );
    }
  }

  Future<void> editGoogle(BuildContext c,CalendarEventItem e)async{
    final ok=await showDialog<bool>(context:c,builder:(_)=>_GoogleEventEdit(event:e));
    if(ok==true)await load();
  }
  @override Widget build(BuildContext context){
    final state=AppStateScope.of(context);
    final linkedEventIds = state.futures
        .where((f) => f.googleEventId != null)
        .map((f) => f.googleEventId!)
        .toSet();
    final dayEvents=events
        .where((e)=>same(e.start,selected) && !linkedEventIds.contains(e.id))
        .toList();
    final local=state.futures.where((f)=>f.scheduledAt!=null&&same(f.scheduledAt!,selected)).toList();
    final tasks=state.tasks.where((t)=>t.deadline!=null&&same(t.deadline!,selected)).toList()
      ..sort((a,b)=>a.deadline!.compareTo(b.deadline!));
    final markerDays=<DateTime>[
      ...events.map((e)=>e.start),
      ...state.futures.where((f)=>f.scheduledAt!=null).map((f)=>f.scheduledAt!),
      ...state.tasks.where((t)=>t.deadline!=null&&!t.completed).map((t)=>t.deadline!),
    ];
    return Scaffold(
      appBar:AppBar(title:const Text('カレンダー',style:TextStyle(fontWeight:FontWeight.w800)),
        actions:[IconButton(tooltip:'今日へ',onPressed:(){final n=DateTime.now();setState((){selected=n;month=DateTime(n.year,n.month);});if(connected)load();},icon:const Icon(Icons.today)),if(connected)IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
      body:PageWrap(child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
        Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
          Row(children:[
            IconButton(onPressed:(){setState(()=>month=DateTime(month.year,month.month-1));load();},icon:const Icon(Icons.chevron_left)),
            Expanded(child:Text('${month.year}年 ${month.month}月',textAlign:TextAlign.center,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold))),
            IconButton(onPressed:(){setState(()=>month=DateTime(month.year,month.month+1));load();},icon:const Icon(Icons.chevron_right)),
          ]),
          _MonthGrid(month:month,selected:selected,markerDays:markerDays,onSelect:(d)=>setState(()=>selected=d)),
        ]))),
        if(!connected) Card(child:ListTile(
          leading:const Icon(Icons.link),title:const Text('Google Calendarを接続'),
          subtitle:const Text('Google予定をNeru Memoryに表示します'),
          trailing:busy?const SizedBox.square(dimension:24,child:CircularProgressIndicator()):FilledButton(onPressed:connect,child:const Text('接続')))),
        if(error!=null) Card(child:ListTile(leading:Icon(Icons.error_outline,color:Theme.of(context).colorScheme.error),title:Text(error!),trailing:IconButton(icon:const Icon(Icons.refresh),onPressed:connected?load:connect))),
        Row(children:[Expanded(child:SectionTitle('${selected.month}/${selected.day} の予定')),Text('${dayEvents.length+local.length+tasks.length}件',style:Theme.of(context).textTheme.labelLarge)]),
        if(dayEvents.isEmpty&&local.isEmpty&&tasks.isEmpty) const EmptyHint('予定はありません'),
        for(final t in tasks) Card(child:ListTile(
          leading:Checkbox(value:t.completed,onChanged:(_)=>state.toggleTask(t)),
          title:Text(t.title),
          subtitle:Text('${hm(t.deadline!)} · やること'),
          trailing:const Icon(Icons.edit_outlined),
          onTap:()async{await editTask(context,t);if(mounted)setState((){});},
        )),
        for(final f in local) Card(child:ListTile(
          leading:const Icon(Icons.push_pin_outlined),title:Text(f.title),
          subtitle:Text('${formatMemoryDateTime(f.scheduledAt)} · Neru Memory'),
          onTap:()async{
            await editFuture(context,f);
            if(mounted){
              setState((){});
              if(connected) await load();
            }
          },
          trailing:f.googleEventId!=null
            ? const Chip(label:Text('Google連携済'))
            : connected?TextButton(onPressed:()async{
            try{
              final created=await GoogleCalendarService.instance.createEvent(title:f.title,start:f.scheduledAt!,description:f.note);
              f.googleEventId=created.id; state.updateFuture(f);
              await load();
              if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Google Calendarに追加しました')));
            }catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyError(e))));}
          },child:const Text('Googleへ')):const Icon(Icons.edit_outlined))),
        for(final e in dayEvents) Card(child:ListTile(
          leading:const Icon(Icons.event),title:Text(e.title),
          subtitle:Text(e.allDay?'終日 · Google Calendar':'${hm(e.start)}–${hm(e.end)} · Google Calendar'),
          trailing:const Icon(Icons.edit_outlined),onTap:()async{await editGoogle(context,e);if(mounted)setState((){});}))),
      ])));
  }
}
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month,required this.selected,required this.markerDays,required this.onSelect});
  final DateTime month,selected; final List<DateTime> markerDays; final ValueChanged<DateTime> onSelect;
  bool same(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month&&a.day==b.day;
  @override Widget build(BuildContext context){
    final first=DateTime(month.year,month.month,1), today=DateTime.now();
    final days=DateTime(month.year,month.month+1,0).day, offset=first.weekday%7;
    const labels=['日','月','火','水','木','金','土'];
    return Column(children:[
      Row(children:[for(final label in labels)Expanded(child:Center(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w600))))]),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:7,childAspectRatio:1.05),
        itemCount:offset+days,itemBuilder:(context,index){
          if(index<offset)return const SizedBox();
          final d=DateTime(month.year,month.month,index-offset+1);
          final has=markerDays.any((x)=>same(x,d)), sel=same(d,selected), isToday=same(d,today);
          return InkWell(onTap:()=>onSelect(d),borderRadius:BorderRadius.circular(30),child:Container(
            margin:const EdgeInsets.all(3),
            decoration:sel?BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,shape:BoxShape.circle):
              isToday?BoxDecoration(border:Border.all(color:Theme.of(context).colorScheme.primary),shape:BoxShape.circle):null,
            child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Text('${d.day}',style:TextStyle(fontWeight:isToday?FontWeight.bold:null)),
              if(has)Icon(Icons.circle,size:7,color:Theme.of(context).colorScheme.primary),
            ])));
        }),
    ]);
  }
}
class _GoogleEventEdit extends StatefulWidget {
  const _GoogleEventEdit({required this.event}); final CalendarEventItem event;
  @override State<_GoogleEventEdit> createState()=>_GoogleEventEditState();
}
class _GoogleEventEditState extends State<_GoogleEventEdit> {
  late final TextEditingController title,desc; late DateTime start,end; bool saving=false;
  @override void initState(){super.initState();title=TextEditingController(text:widget.event.title);desc=TextEditingController(text:widget.event.description);start=widget.event.start;end=widget.event.end;}
  @override void dispose(){title.dispose();desc.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AlertDialog(
    title:const Text('Google予定を編集'),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:title,decoration:const InputDecoration(labelText:'タイトル')),
      ListTile(title:const Text('開始'),subtitle:Text(formatMemoryDateTime(start)),onTap:()async{final v=await pickMemoryDateTime(context,start);if(v!=null&&mounted)setState(()=>start=v);}),
      ListTile(title:const Text('終了'),subtitle:Text(formatMemoryDateTime(end)),onTap:()async{final v=await pickMemoryDateTime(context,end);if(v!=null&&mounted)setState(()=>end=v);}),
      TextField(controller:desc,maxLines:3,decoration:const InputDecoration(labelText:'メモ')),
    ])),
    actions:[
      TextButton(onPressed:saving?null:()=>Navigator.pop(context,false),child:const Text('キャンセル')),
      FilledButton(onPressed:saving?null:()async{
        setState(()=>saving=true);
        try{
          widget.event.title=title.text.trim();widget.event.description=desc.text.trim();widget.event.start=start;widget.event.end=end;
          await GoogleCalendarService.instance.updateEvent(widget.event);
          if(context.mounted)Navigator.pop(context,true);
        }catch(e){if(mounted)setState(()=>saving=false);if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Google予定の更新に失敗しました')));}
      },child:const Text('保存')),
    ]);
}
