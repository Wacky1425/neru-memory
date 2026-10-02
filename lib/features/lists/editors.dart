import 'package:flutter/material.dart';import '../../core/app_state.dart';import '../../core/models.dart';import '../../widgets/date_fields.dart';
import '../../core/google_calendar_service.dart';
import '../goals/goals_page.dart';
List<String> _parseTags(String value) => value
    .split(RegExp(r'[,、\s]+'))
    .map((e) => e.trim().replaceFirst(RegExp(r'^#'), ''))
    .where((e) => e.isNotEmpty)
    .toSet()
    .toList();
String _tagText(List<String> tags) => tags.join(', ');

Future<void> editTask(BuildContext c,MemoryTask t)=>showDialog<void>(context:c,builder:(_)=>_TaskDialog(task:t));
String _bucket(TaskBucket b)=>switch(b){TaskBucket.inbox=>'未分類',TaskBucket.today=>'今日',TaskBucket.soon=>'近いうち',TaskBucket.someday=>'いつか'};
class _TaskDialog extends StatefulWidget{const _TaskDialog({required this.task});final MemoryTask task;@override State<_TaskDialog>createState()=>_TaskDialogState();}
class _TaskDialogState extends State<_TaskDialog>{late final TextEditingController title,note,tags;late TaskBucket bucket;DateTime? deadline;@override void initState(){super.initState();title=TextEditingController(text:widget.task.title);note=TextEditingController(text:widget.task.note);tags=TextEditingController(text:_tagText(widget.task.tags));bucket=widget.task.bucket==TaskBucket.inbox?TaskBucket.soon:widget.task.bucket;deadline=widget.task.deadline;}@override void dispose(){title.dispose();note.dispose();tags.dispose();super.dispose();}@override Widget build(BuildContext c){final s=AppStateScope.of(c);return AlertDialog(title:const Text('やることを編集'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:const InputDecoration(labelText:'タイトル')),const SizedBox(height:12),DropdownButtonFormField<TaskBucket>(initialValue:bucket,items:[TaskBucket.today,TaskBucket.soon,TaskBucket.someday].map((e)=>DropdownMenuItem(value:e,child:Text(_bucket(e)))).toList(),onChanged:(v)=>setState(()=>bucket=v??bucket)),const SizedBox(height:8),ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.event_outlined),title:const Text('期限'),subtitle:Text(formatMemoryDateTime(deadline)),onTap:()async{final v=await pickMemoryDateTime(c,deadline);if(mounted)setState(()=>deadline=v);},trailing:deadline==null?null:IconButton(icon:const Icon(Icons.clear),onPressed:()=>setState(()=>deadline=null))),if(widget.task.goalId!=null)...[
  Builder(builder:(context){
    final goal=s.goals.where((g)=>g.id==widget.task.goalId).firstOrNull;
    if(goal==null)return const SizedBox.shrink();
    return ListTile(
      contentPadding:EdgeInsets.zero,
      leading:const Icon(Icons.flag_outlined),
      title:const Text('関連する目標'),
      subtitle:Text(goal.title),
      trailing:const Icon(Icons.chevron_right),
      onTap:()=>openGoalDetail(context,goal),
    );
  }),
],TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'メモ')),TextField(controller:tags,decoration:const InputDecoration(labelText:'タグ',hintText:'仕事, 買い物, 旅行'))])),actions:[TextButton(onPressed:(){s.deleteTask(widget.task);Navigator.pop(c);},child:const Text('削除')),TextButton(onPressed:(){widget.task.title=title.text.trim().isEmpty?widget.task.title:title.text.trim();s.moveTaskToInbox(widget.task);Navigator.pop(c);},child:const Text('未分類へ戻す')),FilledButton(onPressed:(){if(title.text.trim().isNotEmpty){widget.task.title=title.text.trim();widget.task.note=note.text.trim();widget.task.bucket=bucket;widget.task.deadline=deadline;widget.task.tags=_parseTags(tags.text);s.updateTask(widget.task);}Navigator.pop(c);},child:const Text('保存'))]);}}
Future<void> editWant(BuildContext c,WantItem i)=>showDialog<void>(context:c,builder:(_)=>_WantDialog(item:i));class _WantDialog extends StatefulWidget{const _WantDialog({required this.item});final WantItem item;@override State<_WantDialog>createState()=>_WantDialogState();}class _WantDialogState extends State<_WantDialog>{late final TextEditingController title,waiting,timing,note,budget,tags;late WantStatus status;@override void initState(){super.initState();final i=widget.item;title=TextEditingController(text:i.title);waiting=TextEditingController(text:i.waitingFor);timing=TextEditingController(text:i.timing);note=TextEditingController(text:i.note);budget=TextEditingController(text:i.budget?.toStringAsFixed(0)??'');tags=TextEditingController(text:_tagText(i.tags));status=i.status;}@override void dispose(){for(final c in[title,waiting,timing,note,budget,tags])c.dispose();super.dispose();}@override Widget build(BuildContext c){final s=AppStateScope.of(c);return AlertDialog(title:const Text('買いたいを編集'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:const InputDecoration(labelText:'名前')),TextField(controller:budget,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'予算')),TextField(controller:timing,decoration:const InputDecoration(labelText:'時期（年末・価格が下がったら等）')),TextField(controller:waiting,decoration:const InputDecoration(labelText:'待機条件')),DropdownButtonFormField<WantStatus>(initialValue:status,items:WantStatus.values.map((e)=>DropdownMenuItem(value:e,child:Text(e.name))).toList(),onChanged:(v)=>setState(()=>status=v??status)),TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'メモ')),TextField(controller:tags,decoration:const InputDecoration(labelText:'タグ',hintText:'PC, 趣味, 生活'))])),actions:[TextButton(onPressed:(){s.deleteWant(widget.item);Navigator.pop(c);},child:const Text('削除')),FilledButton(onPressed:(){final i=widget.item;i.title=title.text.trim();i.budget=double.tryParse(budget.text);i.timing=timing.text.trim();i.waitingFor=waiting.text.trim();i.status=status;i.note=note.text.trim();i.tags=_parseTags(tags.text);s.updateWant(i);Navigator.pop(c);},child:const Text('保存'))]);}}
Future<void> editFuture(BuildContext c, FutureItem i) =>
    showDialog<void>(context: c, builder: (_) => _FutureDialog(item: i));

class _FutureDialog extends StatefulWidget {
  const _FutureDialog({required this.item});
  final FutureItem item;

  @override
  State<_FutureDialog> createState() => _FutureDialogState();
}

class _FutureDialogState extends State<_FutureDialog> {
  late final TextEditingController title;
  late final TextEditingController timing;
  late final TextEditingController note;
  late final TextEditingController tags;
  late FutureStatus status;
  DateTime? scheduledAt;
  bool saving = false;

  bool get linked => widget.item.googleEventId != null;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.item.title);
    timing = TextEditingController(text: widget.item.timing);
    note = TextEditingController(text: widget.item.note);
    tags = TextEditingController(text: _tagText(widget.item.tags));
    status = widget.item.status;
    scheduledAt = widget.item.scheduledAt;
  }

  @override
  void dispose() {
    title.dispose();
    timing.dispose();
    note.dispose();
    tags.dispose();
    super.dispose();
  }

  Future<void> _save(AppState state) async {
    final newTitle = title.text.trim();
    if (newTitle.isEmpty) return;
    if (linked && scheduledAt == null) {
      _message('Google連携中は日時を外せません。先に「連携解除」をしてください。');
      return;
    }

    setState(() => saving = true);
    try {
      if (linked) {
        await GoogleCalendarService.instance.updateEvent(
          CalendarEventItem(
            id: widget.item.googleEventId!,
            title: newTitle,
            start: scheduledAt!,
            end: scheduledAt!.add(const Duration(hours: 1)),
            description: note.text.trim(),
          ),
        );
      }

      final item = widget.item;
      item.title = newTitle;
      item.timing = timing.text.trim();
      item.scheduledAt = scheduledAt;
      item.status = scheduledAt == null ? status : FutureStatus.scheduled;
      item.note = note.text.trim();
      item.tags = _parseTags(tags.text);

      // Once a Future has a concrete date/time, make Google Calendar the
      // durable schedule automatically when Calendar authorization exists.
      if (!linked && scheduledAt != null) {
        final connected = GoogleCalendarService.instance.isConnected ||
            await GoogleCalendarService.instance.restoreConnection();
        if (connected) {
          final created = await GoogleCalendarService.instance.createEvent(
            title: newTitle,
            start: scheduledAt!,
            description: note.text.trim(),
          );
          item.googleEventId = created.id;
        }
      }

      state.updateFuture(item);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        _message('Google Calendarへの反映に失敗しました。接続を確認して再試行してください。');
      }
    }
  }

  Future<void> _unlink(AppState state) async {
    widget.item.googleEventId = null;
    state.updateFuture(widget.item);
    if (mounted) setState(() {});
    _message('Googleとの連携だけ解除しました。Google側の予定は残っています。');
  }

  Future<void> _deleteEverywhere(AppState state) async {
    final eventId = widget.item.googleEventId;
    if (eventId == null) return;

    setState(() => saving = true);
    try {
      await GoogleCalendarService.instance.deleteEvent(eventId);
      state.deleteFuture(widget.item);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        _message('Google Calendarの削除に失敗しました。Futureは削除していません。');
      }
    }
  }

  Future<void> _deleteFuture(AppState state) async {
    if (!linked) {
      state.deleteFuture(widget.item);
      if (mounted) Navigator.pop(context);
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Futureを削除'),
        content: const Text('Google Calendarにも連携中です。どこまで削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(c, 'local'), child: const Text('Futureだけ削除')),
          FilledButton(onPressed: () => Navigator.pop(c, 'both'), child: const Text('両方削除')),
        ],
      ),
    );
    if (choice == 'local') {
      state.deleteFuture(widget.item);
      if (mounted) Navigator.pop(context);
    } else if (choice == 'both') {
      await _deleteEverywhere(state);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext c) {
    final state = AppStateScope.of(c);
    return AlertDialog(
      title: const Text('予定候補を編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (linked)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.cloud_done_outlined),
                title: Text('Google Calendar連携中'),
                subtitle: Text('保存するとGoogle側にも反映されます'),
              ),
            TextField(controller: title, decoration: const InputDecoration(labelText: '予定')),
            TextField(controller: timing, decoration: const InputDecoration(labelText: '曖昧な時期 例：冬 / 来年')),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('日時を確定'),
              subtitle: Text(formatMemoryDateTime(scheduledAt)),
              onTap: () async {
                final value = await pickMemoryDateTime(c, scheduledAt);
                if (mounted) setState(() => scheduledAt = value ?? scheduledAt);
              },
              trailing: scheduledAt == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: saving ? null : () => setState(() => scheduledAt = null),
                    ),
            ),
            DropdownButtonFormField<FutureStatus>(
              initialValue: status,
              items: FutureStatus.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: saving ? null : (v) => setState(() => status = v ?? status),
            ),
            TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'メモ')),
            TextField(controller: tags, decoration: const InputDecoration(labelText: 'タグ', hintText: '旅行, 友達, 行きたい')),
            if (linked)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: saving ? null : () => _unlink(state),
                  icon: const Icon(Icons.link_off),
                  label: const Text('Google連携だけ解除'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => _deleteFuture(state),
          child: const Text('削除'),
        ),
        FilledButton(
          onPressed: saving ? null : () => _save(state),
          child: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
