import 'package:flutter/material.dart';import '../../core/app_state.dart';import '../../core/models.dart';import '../../widgets/common.dart';import '../inbox/inbox_page.dart';import '../tags/tag_results_page.dart';import '../tags/tags_page.dart';import '../goals/goals_page.dart';import 'editors.dart';

Widget _taggedSubtitle(BuildContext context,List<String> lines,List<String> tags){
  final text=lines.where((e)=>e.trim().isNotEmpty).join(' · ');
  if(tags.isEmpty)return text.isEmpty?const SizedBox.shrink():Text(text,maxLines:2,overflow:TextOverflow.ellipsis);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    if(text.isNotEmpty)Text(text,maxLines:2,overflow:TextOverflow.ellipsis),
    const SizedBox(height:4),
    Wrap(spacing:4,runSpacing:2,children:[
      for(final tag in tags.take(4))ActionChip(
        label:Text('#$tag'),
        onPressed:()=>openTagResults(context,tag),
        visualDensity:VisualDensity.compact,
        padding:EdgeInsets.zero,
        materialTapTargetSize:MaterialTapTargetSize.shrinkWrap,
      ),
    ]),
  ]);
}

class ListsPage extends StatefulWidget{const ListsPage({super.key});@override State<ListsPage>createState()=>_ListsPageState();}class _ListsPageState extends State<ListsPage>with SingleTickerProviderStateMixin{late final TabController controller=TabController(length:3,vsync:this);@override void dispose(){controller.dispose();super.dispose();}@override Widget build(BuildContext c){final s=AppStateScope.of(c);return Scaffold(appBar:AppBar(title:const Text('リスト',style:TextStyle(fontWeight:FontWeight.w800)),actions:[IconButton(tooltip:'タグ',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const TagsPage())),icon:const Icon(Icons.tag)),TextButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const InboxPage())),icon:const Icon(Icons.inbox_outlined),label:Text('未分類 ${s.inbox.length}'))],bottom:TabBar(controller:controller,tabs:const[Tab(text:'やること'),Tab(text:'買いたい'),Tab(text:'予定候補')])),body:PageWrap(child:TabBarView(controller:controller,children:const[_Tasks(),_Wants(),_Futures()])));}}
class _Tasks extends StatefulWidget{const _Tasks();@override State<_Tasks> createState()=>_TasksState();}
class _TasksState extends State<_Tasks>{
  bool showCompleted=false;
  DateTime _day(DateTime d)=>DateTime(d.year,d.month,d.day);
  Future<void> _quickTask(BuildContext c,AppState s,MemoryTask t)async{
    final action=await showModalBottomSheet<String>(context:c,builder:(b)=>SafeArea(child:Wrap(children:[
      ListTile(leading:const Icon(Icons.check_circle_outline),title:const Text('完了にする'),onTap:()=>Navigator.pop(b,'done')),
      ListTile(leading:const Icon(Icons.today),title:const Text('今日'),onTap:()=>Navigator.pop(b,'today')),
      ListTile(leading:const Icon(Icons.wb_sunny_outlined),title:const Text('明日'),onTap:()=>Navigator.pop(b,'tomorrow')),
      ListTile(leading:const Icon(Icons.next_week_outlined),title:const Text('来週'),onTap:()=>Navigator.pop(b,'week')),
      ListTile(leading:const Icon(Icons.edit_outlined),title:const Text('編集'),onTap:()=>Navigator.pop(b,'edit')),
      ListTile(leading:const Icon(Icons.delete_outline),title:const Text('削除'),onTap:()=>Navigator.pop(b,'delete')),
    ])));
    if(!mounted||action==null)return;
    final now=_day(DateTime.now());
    if(action=='done')s.toggleTask(t);
    if(action=='today')s.rescheduleTask(t,now);
    if(action=='tomorrow')s.rescheduleTask(t,now.add(const Duration(days:1)));
    if(action=='week')s.rescheduleTask(t,now.add(const Duration(days:7)),bucket:TaskBucket.soon);
    if(action=='edit')editTask(c,t);
    if(action=='delete')s.deleteTask(t);
  }
  Widget _taskCard(BuildContext c,AppState s,MemoryTask t,{bool overdue=false})=>Dismissible(
    key:ValueKey('task_'+t.id),
    background:Container(alignment:Alignment.centerLeft,padding:const EdgeInsets.symmetric(horizontal:24),child:const Icon(Icons.check)),
    secondaryBackground:Container(alignment:Alignment.centerRight,padding:const EdgeInsets.symmetric(horizontal:24),child:const Icon(Icons.schedule)),
    confirmDismiss:(direction)async{
      if(direction==DismissDirection.startToEnd){s.toggleTask(t);return false;}
      await _quickTask(c,s,t);return false;
    },
    child:Card(child:CheckboxListTile(value:t.completed,onChanged:(_)=>s.toggleTask(t),onTap:()=>editTask(c,t),title:Text(t.title,style:overdue?const TextStyle(fontWeight:FontWeight.w700):null),subtitle:_taggedSubtitle(c,[if(overdue&&t.deadline!=null)'期限 '+t.deadline!.month.toString()+'/'+t.deadline!.day.toString(),if(t.goalId!=null)'目標: '+(s.goals.where((g)=>g.id==t.goalId).firstOrNull?.title??'リンク切れ'),t.note],t.tags),controlAffinity:ListTileControlAffinity.leading,secondary:IconButton(icon:const Icon(Icons.more_horiz),onPressed:()=>_quickTask(c,s,t))))
  );
  @override Widget build(BuildContext c){final s=AppStateScope.of(c);final now=DateTime.now();final start=DateTime(now.year,now.month,now.day);final overdue=s.tasks.where((t)=>!t.completed&&t.deadline!=null&&t.deadline!.isBefore(start)).toList()..sort((a,b)=>a.deadline!.compareTo(b.deadline!));return ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[
if(overdue.isNotEmpty)...[const SectionTitle('期限超過'),...overdue.map((t)=>_taskCard(c,s,t,overdue:true))],
for(final b in[TaskBucket.today,TaskBucket.soon,TaskBucket.someday])...[SectionTitle(switch(b){TaskBucket.today=>'今日',TaskBucket.soon=>'近いうち',_=>'いつか'}),...(s.tasks.where((t)=>t.bucket==b&&!t.completed&&!overdue.contains(t)).toList()..sort((a,b){if(a.deadline==null&&b.deadline==null)return 0;if(a.deadline==null)return 1;if(b.deadline==null)return -1;return a.deadline!.compareTo(b.deadline!);})).map((t)=>_taskCard(c,s,t))],
ListTile(contentPadding:EdgeInsets.zero,title:Text('完了済み ${s.tasks.where((t)=>t.completed).length}件'),trailing:Icon(showCompleted?Icons.expand_less:Icons.expand_more),onTap:()=>setState(()=>showCompleted=!showCompleted)),
if(showCompleted)...s.tasks.where((t)=>t.completed).map((t)=>ListTile(title:Text(t.title,style:const TextStyle(decoration:TextDecoration.lineThrough)),leading:IconButton(icon:const Icon(Icons.check_circle),onPressed:()=>s.toggleTask(t)),trailing:IconButton(icon:const Icon(Icons.edit_outlined),onPressed:()=>editTask(c,t))))
]);}}
class _Wants extends StatelessWidget{const _Wants();@override Widget build(BuildContext c){final s=AppStateScope.of(c);return ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[for(final w in s.wants)Card(child:ListTile(onTap:()=>editWant(c,w),leading:const Icon(Icons.shopping_bag_outlined),title:Text(w.title),subtitle:_taggedSubtitle(c,[if(w.budget!=null)'¥${w.budget!.round()}',w.timing,w.waitingFor],w.tags),trailing:const Icon(Icons.chevron_right))) ]);}}
class _Futures extends StatelessWidget{const _Futures();@override Widget build(BuildContext c){final s=AppStateScope.of(c);return ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[for(final f in s.futures)Card(child:ListTile(onTap:()=>editFuture(c,f),leading:const Icon(Icons.push_pin_outlined),title:Text(f.title),subtitle:_taggedSubtitle(c,[f.status.name,f.timing],f.tags),trailing:f.googleEventId==null?null:const Icon(Icons.event_available_outlined))) ]);}}