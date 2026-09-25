import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import 'editors.dart';

class ListsPage extends StatefulWidget { const ListsPage({super.key}); @override State<ListsPage> createState()=>_ListsPageState(); }
class _ListsPageState extends State<ListsPage> with SingleTickerProviderStateMixin {
 late final TabController controller=TabController(length:3,vsync:this);
 @override void dispose(){controller.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('リスト',style:TextStyle(fontWeight:FontWeight.w800)),bottom:TabBar(controller:controller,tabs:const [Tab(text:'やること'),Tab(text:'買いたい'),Tab(text:'予定候補')])),body:PageWrap(child:TabBarView(controller:controller,children:const [_Tasks(),_Wants(),_Futures()])));
}
class _Tasks extends StatelessWidget { const _Tasks(); @override Widget build(BuildContext context){final s=AppStateScope.of(context);return ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[for(final b in TaskBucket.values)...[SectionTitle(_bucket(b)),...s.tasks.where((t)=>t.bucket==b&&!t.completed).map((t)=>Card(child:CheckboxListTile(value:t.completed,onChanged:(_)=>s.toggleTask(t),title:Text(t.title),controlAffinity:ListTileControlAffinity.leading,secondary:IconButton(icon:const Icon(Icons.edit_outlined),onPressed:()=>editTask(context,t)))))],const SectionTitle('完了'),...s.tasks.where((t)=>t.completed).map((t)=>ListTile(leading:IconButton(icon:const Icon(Icons.check_circle),onPressed:()=>s.toggleTask(t)),title:Text(t.title,style:const TextStyle(decoration:TextDecoration.lineThrough)),trailing:IconButton(icon:const Icon(Icons.edit_outlined),onPressed:()=>editTask(context,t))))]);} String _bucket(TaskBucket b)=>switch(b){TaskBucket.inbox=>'Inbox',TaskBucket.today=>'今日',TaskBucket.soon=>'近いうち',TaskBucket.someday=>'いつか'}; }
class _Wants extends StatelessWidget { const _Wants(); @override Widget build(BuildContext context){final s=AppStateScope.of(context);return ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[for(final w in s.wants)Card(child:ListTile(onTap:()=>editWant(context,w),leading:const Icon(Icons.shopping_bag_outlined),title:Text(w.title),subtitle:Text([if(w.budget!=null)'予算 ¥${w.budget!.round()}',if(w.waitingFor.isNotEmpty)w.waitingFor].join('  ·  ')),trailing:const Icon(Icons.chevron_right)))]);} }
class _Futures extends StatelessWidget { const _Futures(); @override Widget build(BuildContext context){final s=AppStateScope.of(context);return ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[for(final f in s.futures)Card(child:ListTile(onTap:()=>editFuture(context,f),leading:const Icon(Icons.push_pin_outlined),title:Text(f.title),subtitle:Text(f.status.name),trailing:Text(f.timing))) ]);} }
