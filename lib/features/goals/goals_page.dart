import 'package:flutter/material.dart';import '../../core/app_state.dart';import '../../core/models.dart';import '../../widgets/common.dart';import '../../widgets/date_fields.dart';import '../tags/tag_results_page.dart';
class GoalsPage extends StatelessWidget{const GoalsPage({super.key});@override Widget build(BuildContext c){final s=AppStateScope.of(c);return Scaffold(appBar:AppBar(title:const Text('目標',style:TextStyle(fontWeight:FontWeight.w800))),body:PageWrap(child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[const SectionTitle('ACTIVE GOALS'),...s.goals.where((g)=>g.status==GoalStatus.active).map((g)=>_card(c,g)),const SectionTitle('OTHER'),...s.goals.where((g)=>g.status!=GoalStatus.active).map((g)=>_card(c,g))])));}Widget _card(BuildContext c,GoalItem g)=>Card(child:ListTile(onTap:()=>openGoalDetail(c,g),title:Text(g.title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const SizedBox(height:8),LinearProgressIndicator(value:g.progress.clamp(0.0,1.0)),const SizedBox(height:6),Text('${(g.progress*100).round()}%${g.deadlineLabel.isEmpty?'':' · ${g.deadlineLabel}'}')]),trailing:const Icon(Icons.chevron_right)));}
Future<void> openGoalDetail(BuildContext context, GoalItem goal) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _Detail(goal: goal),
  );
}

class _Detail extends StatelessWidget{const _Detail({required this.goal});final GoalItem goal;@override Widget build(BuildContext c){final s=AppStateScope.of(c);final ms=s.milestones.where((m)=>m.goalId==goal.id);return SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(goal.title,style:Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800))),IconButton(onPressed:()=>showDialog<void>(context:c,builder:(_)=>_GoalEdit(goal:goal)),icon:const Icon(Icons.edit_outlined))]),Text(goal.deadlineLabel),const SizedBox(height:12),LinearProgressIndicator(value:goal.progress.clamp(0.0,1.0)),if(goal.tags.isNotEmpty)...[const SizedBox(height:12),Wrap(spacing:4,children:[for(final tag in goal.tags)ActionChip(label:Text('#$tag'),visualDensity:VisualDensity.compact,onPressed:()=>openTagResults(c,tag))])],if(goal.why.isNotEmpty)...[const SizedBox(height:16),const Text('WHY',style:TextStyle(fontWeight:FontWeight.bold)),Text(goal.why)],const SizedBox(height:18),const Text('MILESTONES',style:TextStyle(fontWeight:FontWeight.bold)),for(final m in ms)ListTile(contentPadding:EdgeInsets.zero,title:Text(m.title),subtitle:LinearProgressIndicator(value:m.progress.clamp(0.0,1.0)),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='task'){final before=s.tasks.length;s.addTaskFromMilestone(m);ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s.tasks.length>before?'マイルストーンを「やること」に追加しました':'同じ「やること」が既にあります')));}else if(v=='edit'){showDialog<void>(context:c,builder:(_)=>_MilestoneEdit(item:m));}},itemBuilder:(_)=>const [PopupMenuItem(value:'task',child:Text('やることに追加')),PopupMenuItem(value:'edit',child:Text('編集'))]),onTap:()=>showDialog<void>(context:c,builder:(_)=>_MilestoneEdit(item:m))),TextButton.icon(onPressed:()=>showDialog<void>(context:c,builder:(_)=>_MilestoneAdd(goalId:goal.id)),icon:const Icon(Icons.add),label:const Text('追加')),if(goal.nextAction.isNotEmpty)...[const SizedBox(height:12),const Text('NEXT ACTION',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:6),Row(children:[Expanded(child:Text(goal.nextAction)),FilledButton.tonalIcon(onPressed:(){final before=s.tasks.length;final task=s.addTaskFromGoal(goal);if(task==null)return;final added=s.tasks.length>before;ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(added?'次の行動を「やること」に追加しました':'同じ「やること」が既にあります')));},icon:const Icon(Icons.add_task),label:const Text('Task化'))])]])));}}
class _GoalEdit extends StatefulWidget{const _GoalEdit({required this.goal});final GoalItem goal;@override State<_GoalEdit>createState()=>_GoalEditState();}class _GoalEditState extends State<_GoalEdit>{late final TextEditingController title,deadlineText,why,next,tags;late double progress;late GoalStatus status;DateTime? date;@override void initState(){super.initState();final g=widget.goal;title=TextEditingController(text:g.title);deadlineText=TextEditingController(text:g.deadline);why=TextEditingController(text:g.why);next=TextEditingController(text:g.nextAction);tags=TextEditingController(text:g.tags.join(', '));progress=g.progress;status=g.status;date=g.deadlineDate;}@override void dispose(){title.dispose();deadlineText.dispose();why.dispose();next.dispose();tags.dispose();super.dispose();}@override Widget build(BuildContext c){final s=AppStateScope.of(c);return AlertDialog(title:const Text('目標を編集'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:const InputDecoration(labelText:'目標')),ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.event_outlined),title:const Text('期限日'),subtitle:Text(formatMemoryDate(date)),onTap:()async{final v=await pickMemoryDate(c,date);if(mounted)setState(()=>date=v);},trailing:date==null?null:IconButton(icon:const Icon(Icons.clear),onPressed:()=>setState(()=>date=null))),TextField(controller:deadlineText,decoration:const InputDecoration(labelText:'または曖昧な期限（3年以内・継続など）')),TextField(controller:why,decoration:const InputDecoration(labelText:'なぜ？')),TextField(controller:next,decoration:const InputDecoration(labelText:'次の行動')),TextField(controller:tags,decoration:const InputDecoration(labelText:'タグ',hintText:'長期, 旅行, キャリア')),DropdownButtonFormField<GoalStatus>(initialValue:status,items:GoalStatus.values.map((e)=>DropdownMenuItem(value:e,child:Text(e.name))).toList(),onChanged:(v)=>setState(()=>status=v??status)),Text('進捗 ${(progress*100).round()}%'),Slider(value:progress.clamp(0.0,1.0),divisions:20,onChanged:(v)=>setState(()=>progress=v))])),actions:[TextButton(onPressed:(){s.deleteGoal(widget.goal);Navigator.pop(c);Navigator.pop(c);},child:const Text('削除')),FilledButton(onPressed:(){final g=widget.goal;g.title=title.text.trim();g.deadline=deadlineText.text.trim();g.deadlineDate=date;g.why=why.text.trim();g.nextAction=next.text.trim();g.progress=progress;g.status=status;g.tags=tags.text.split(RegExp(r'[,、\s]+')).map((e)=>e.trim().replaceFirst(RegExp(r'^#'),'')).where((e)=>e.isNotEmpty).toSet().toList();s.updateGoal(g);Navigator.pop(c);},child:const Text('保存'))]);}}
class _MilestoneAdd extends StatefulWidget{const _MilestoneAdd({required this.goalId});final String goalId;@override State<_MilestoneAdd>createState()=>_MilestoneAddState();}class _MilestoneAddState extends State<_MilestoneAdd>{final x=TextEditingController();@override void dispose(){x.dispose();super.dispose();}@override Widget build(BuildContext c){final s=AppStateScope.of(c);return AlertDialog(title:const Text('マイルストーンを追加'),content:TextField(controller:x,autofocus:true),actions:[FilledButton(onPressed:(){if(x.text.trim().isNotEmpty)s.addMilestone(widget.goalId,x.text.trim());Navigator.pop(c);},child:const Text('追加'))]);}}

class _MilestoneEdit extends StatefulWidget{
  const _MilestoneEdit({required this.item});
  final MilestoneItem item;
  @override State<_MilestoneEdit> createState()=>_MilestoneEditState();
}
class _MilestoneEditState extends State<_MilestoneEdit>{
  late final TextEditingController title,note;
  late double progress,weight;
  @override void initState(){
    super.initState();
    title=TextEditingController(text:widget.item.title);
    note=TextEditingController(text:widget.item.note);
    progress=widget.item.progress;
    weight=widget.item.weight;
  }
  @override void dispose(){title.dispose();note.dispose();super.dispose();}
  @override Widget build(BuildContext c){
    final s=AppStateScope.of(c);
    return AlertDialog(
      title:const Text('マイルストーンを編集'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'名前')),
        TextField(controller:note,maxLines:2,decoration:const InputDecoration(labelText:'メモ')),
        const SizedBox(height:12),
        Text('進捗 ${(progress*100).round()}%'),
        Slider(value:progress.clamp(0.0,1.0),divisions:20,onChanged:(v)=>setState(()=>progress=v)),
        Text('重み ${weight.toStringAsFixed(1)}'),
        Slider(value:weight.clamp(0.5,5.0),min:0.5,max:5.0,divisions:9,onChanged:(v)=>setState(()=>weight=v)),
      ])),
      actions:[
        TextButton(onPressed:(){s.deleteMilestone(widget.item);Navigator.pop(c);},child:const Text('削除')),
        FilledButton(onPressed:(){
          if(title.text.trim().isEmpty)return;
          widget.item.title=title.text.trim();
          widget.item.note=note.text.trim();
          widget.item.progress=progress;
          widget.item.weight=weight;
          s.updateMilestone(widget.item);
          Navigator.pop(c);
        },child:const Text('保存')),
      ],
    );
  }
}
