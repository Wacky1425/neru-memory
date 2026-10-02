import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/google_calendar_service.dart';
import '../../widgets/common.dart';
import '../../widgets/date_fields.dart';
import '../capture/quick_capture.dart';
import '../inbox/inbox_page.dart';
import '../lists/editors.dart';
import '../goals/goals_page.dart';

class HomePage extends StatefulWidget{const HomePage({super.key});@override State<HomePage>createState()=>_HomePageState();}
class _HomePageState extends State<HomePage>{
  List<CalendarEventItem> google=[]; bool loading=false;
  bool same(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month&&a.day==b.day;
  @override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_)=>refreshGoogle());}
  Future<void> refreshGoogle()async{
    setState(()=>loading=true);
    try{
      final ready=GoogleCalendarService.instance.isConnected||await GoogleCalendarService.instance.restoreConnection();
      if(!ready){if(mounted)setState(()=>loading=false);return;}
      final now=DateTime.now();google=await GoogleCalendarService.instance.listEvents(DateTime(now.year,now.month,now.day),now.add(const Duration(days:14)));}catch(_){}
    if(mounted)setState(()=>loading=false);
  }
  @override Widget build(BuildContext context){
    final s=AppStateScope.of(context),now=DateTime.now();
    final todayTasks=s.tasks.where((t)=>!t.completed&&(t.bucket==TaskBucket.today||(t.deadline!=null&&same(t.deadline!,now)))).toList();
    final overdue=s.tasks.where((t)=>!t.completed&&t.deadline!=null&&t.deadline!.isBefore(DateTime(now.year,now.month,now.day))).toList()..sort((a,b)=>a.deadline!.compareTo(b.deadline!));
    final todayFuture=s.futures.where((f)=>f.scheduledAt!=null&&same(f.scheduledAt!,now)).toList();
    final linkedIds=s.futures.where((f)=>f.googleEventId!=null).map((f)=>f.googleEventId!).toSet();
    final todayGoogle=google.where((e)=>same(e.start,now)&&!linkedIds.contains(e.id)).toList();
    final upcomingTasks=s.tasks.where((t)=>!t.completed&&t.deadline!=null&&t.deadline!.isAfter(now)&&!same(t.deadline!,now)).toList()..sort((a,b)=>a.deadline!.compareTo(b.deadline!));
    final upcomingFuture=s.futures.where((f)=>f.scheduledAt!=null&&f.scheduledAt!.isAfter(now)&&!same(f.scheduledAt!,now)).toList()..sort((a,b)=>a.scheduledAt!.compareTo(b.scheduledAt!));
    final upcomingGoogle=google.where((e)=>e.start.isAfter(now)&&!same(e.start,now)&&!linkedIds.contains(e.id)).toList();
    final goals=s.goals.where((g)=>g.status==GoalStatus.active).take(3).toList();
    final remember=s.rememberSuggestion;
    return Scaffold(appBar:AppBar(title:const Text('NeruMemory',style:TextStyle(fontWeight:FontWeight.w800)),actions:[
      Stack(children:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const InboxPage())),icon:const Icon(Icons.inbox_outlined)),if(s.inbox.isNotEmpty)Positioned(right:7,top:6,child:CircleAvatar(radius:8,child:Text('${s.inbox.length}',style:const TextStyle(fontSize:9))))]),
      IconButton(onPressed:()=>showSearch(context:context,delegate:MemorySearch(s)),icon:const Icon(Icons.search)),
    ]),body:PageWrap(child:RefreshIndicator(onRefresh:refreshGoogle,child:ListView(padding:const EdgeInsets.fromLTRB(18,4,18,100),children:[
      Text('${now.month}月${now.day}日',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w700)),
      const SizedBox(height:14),InkWell(borderRadius:BorderRadius.circular(14),onTap:()=>showQuickCapture(context),child:const IgnorePointer(child:TextField(decoration:InputDecoration(prefixIcon:Icon(Icons.add),hintText:'何か覚えておく…')))),
      if(overdue.isNotEmpty)...[
        const SectionTitle('OVERDUE'),
        for(final t in overdue)Card(child:ListTile(
          leading:Checkbox(value:t.completed,onChanged:(_)=>s.toggleTask(t)),
          title:Text(t.title,style:const TextStyle(fontWeight:FontWeight.w700)),
          subtitle:Text('期限超過 · ${formatMemoryDateTime(t.deadline)}'),
          trailing:const Icon(Icons.edit_outlined),onTap:()=>editTask(context,t))),
      ],
      const SectionTitle('TODAY'),
      if(todayGoogle.isEmpty&&todayTasks.isEmpty&&todayFuture.isEmpty)const EmptyHint('今日の予定はありません'),
      for(final e in todayGoogle)Card(child:ListTile(leading:const Icon(Icons.event),title:Text(e.title),subtitle:Text('Google Calendar · ${_time(e.start)}'))),
      for(final t in todayTasks)Card(child:ListTile(
        leading:Checkbox(value:t.completed,onChanged:(_)=>s.toggleTask(t)),
        title:Text(t.title),
        subtitle:Text(t.deadline==null?'今日のやること':'期限 ${formatMemoryDateTime(t.deadline)}'),
        trailing:const Icon(Icons.edit_outlined),
        onTap:()=>editTask(context,t),
      )),
      for(final f in todayFuture)Card(child:ListTile(onTap:()=>editFuture(context,f),leading:const Icon(Icons.push_pin_outlined),title:Text(f.title),subtitle:Text(formatMemoryDateTime(f.scheduledAt)))),
      const SectionTitle('NEXT'),
      for(final e in upcomingGoogle.take(3))ListTile(leading:const Icon(Icons.event_outlined),title:Text(e.title),subtitle:Text('${e.start.month}/${e.start.day} ${_time(e.start)} · Google')),
      for(final t in upcomingTasks.take(3))ListTile(leading:const Icon(Icons.task_alt),title:Text(t.title),subtitle:Text('期限 ${formatMemoryDateTime(t.deadline)}')),
      for(final f in upcomingFuture.take(3))ListTile(leading:const Icon(Icons.push_pin_outlined),title:Text(f.title),subtitle:Text(formatMemoryDateTime(f.scheduledAt))),
      const SectionTitle('GOALS'),for(final g in goals)Card(child:InkWell(borderRadius:BorderRadius.circular(12),onTap:()=>openGoalDetail(context,g),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(g.title,style:const TextStyle(fontWeight:FontWeight.bold))),Text('${(g.progress*100).round()}%')]),const SizedBox(height:8),LinearProgressIndicator(value:g.progress.clamp(0.0,1.0)),if(g.nextAction.isNotEmpty)...[const SizedBox(height:8),Row(children:[Expanded(child:Text(g.nextAction)),IconButton(tooltip:'Task化',onPressed:(){final before=s.tasks.length;s.addTaskFromGoal(g);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s.tasks.length>before?'次の行動を「やること」に追加しました':'同じ「やること」が既にあります')));},icon:const Icon(Icons.add_task))])]])))),
      const SectionTitle('REMEMBER'),
      if(remember==null)
        const EmptyHint('今は思い出すものはありません')
      else
        Card(child:Padding(padding:const EdgeInsets.fromLTRB(16,14,12,10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Icon(remember.type=='want'?Icons.shopping_bag_outlined:remember.type=='future'?Icons.explore_outlined:Icons.flag_outlined),
            const SizedBox(width:10),
            Expanded(child:Text(remember.title,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:16))),
            Text('${remember.ageDays}日',style:Theme.of(context).textTheme.labelMedium),
          ]),
          const SizedBox(height:8),
          Text(remember.reason),
          const SizedBox(height:10),
          Wrap(spacing:6,runSpacing:4,children:[
            TextButton(onPressed:()=>s.rememberLater(remember),child:const Text('あとで')),
            TextButton(onPressed:()=>s.rememberHide(remember),child:const Text('しばらく出さない')),
            FilledButton.tonal(onPressed:()async{
              final item=s.rememberItem(remember);
              if(item is WantItem)await editWant(context,item);
              if(item is FutureItem)await editFuture(context,item);
              if(item is GoalItem){await openGoalDetail(context,item);s.rememberReviewed(remember);return;}
              s.rememberReviewed(remember);
            },child:const Text('確認する')),
          ]),
        ]))),
    ]))));
  }
  static String _time(DateTime d)=>'${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}
class MemorySearch extends SearchDelegate<String>{
  MemorySearch(this.s);
  final AppState s;
  String filter='all';

  @override List<Widget> buildActions(BuildContext c)=>[
    PopupMenuButton<String>(
      tooltip:'種類で絞り込み',
      icon:Icon(filter=='all'?Icons.filter_list:Icons.filter_alt),
      initialValue:filter,
      onSelected:(v){filter=v;showSuggestions(c);},
      itemBuilder:(_)=>const[
        PopupMenuItem(value:'all',child:Text('すべて')),
        PopupMenuItem(value:'task',child:Text('やること')),
        PopupMenuItem(value:'want',child:Text('買いたい')),
        PopupMenuItem(value:'future',child:Text('予定')),
        PopupMenuItem(value:'goal',child:Text('目標')),
        PopupMenuItem(value:'inbox',child:Text('未分類')),
      ],
    ),
    if(query.isNotEmpty)IconButton(onPressed:()=>query='',icon:const Icon(Icons.clear)),
  ];

  @override Widget buildLeading(BuildContext c)=>IconButton(onPressed:()=>close(c,''),icon:const Icon(Icons.arrow_back));
  @override Widget buildResults(BuildContext c)=>_body(c);
  @override Widget buildSuggestions(BuildContext c)=>_body(c);

  Widget _body(BuildContext context){
    final q=query.trim().toLowerCase();
    bool has(String x)=>q.isEmpty||x.toLowerCase().contains(q);
    bool show(String type)=>filter=='all'||filter==type;
    final rows=<_MemorySearchRow>[];

    if(show('task')) rows.addAll(s.tasks.where((x)=>has('${x.title} ${x.note} ${x.tags.join(' ')}')).map((x)=>_MemorySearchRow('やること',x.title,Icons.task_alt,()=>editTask(context,x),x.completed?'完了':x.bucket.name)));
    if(show('want')) rows.addAll(s.wants.where((x)=>has('${x.title} ${x.note} ${x.timing} ${x.waitingFor} ${x.tags.join(' ')}')).map((x)=>_MemorySearchRow('買いたい',x.title,Icons.shopping_bag_outlined,()=>editWant(context,x),x.status.name)));
    if(show('future')) rows.addAll(s.futures.where((x)=>has('${x.title} ${x.note} ${x.timing} ${x.tags.join(' ')}')).map((x)=>_MemorySearchRow('予定',x.title,Icons.push_pin_outlined,()=>editFuture(context,x),x.status.name)));
    if(show('goal')) rows.addAll(s.goals.where((x)=>has('${x.title} ${x.why} ${x.nextAction} ${x.tags.join(' ')}')).map((x)=>_MemorySearchRow('目標',x.title,Icons.flag_outlined,()=>openGoalDetail(context,x),x.status.name)));
    if(show('inbox')) rows.addAll(s.inbox.where((x)=>has(x.text)).map((x)=>_MemorySearchRow('未分類',x.text,Icons.inbox_outlined,null,'')));

    if(q.isEmpty&&filter=='all')return const Center(child:Text('キーワード検索、または右上から種類を絞り込み'));
    if(rows.isEmpty)return const Center(child:Text('見つかりませんでした'));
    return ListView(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,8,16,4),child:Text('${rows.length}件',style:Theme.of(context).textTheme.labelLarge)),
      for(final row in rows)ListTile(
        leading:Icon(row.icon),title:Text(row.title),
        subtitle:Text(row.detail.isEmpty?row.type:'${row.type} · ${row.detail}'),
        trailing:row.onTap==null?null:const Icon(Icons.chevron_right),onTap:row.onTap,
      ),
    ]);
  }
}

class _MemorySearchRow{
  const _MemorySearchRow(this.type,this.title,this.icon,this.onTap,this.detail);
  final String type,title,detail;
  final IconData icon;
  final VoidCallback? onTap;
}
