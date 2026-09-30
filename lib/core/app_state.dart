import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';import 'cloud_store.dart';import 'trash_entry.dart';import 'notification_service.dart';import 'android_widget_bridge.dart';

class RememberSuggestion {
  const RememberSuggestion({
    required this.type,
    required this.id,
    required this.title,
    required this.reason,
    required this.ageDays,
  });
  final String type,id,title,reason;
  final int ageDays;
}

class AppState extends ChangeNotifier{
  AppState._(); ThemeMode themeMode=ThemeMode.light;
  final tasks=<MemoryTask>[],wants=<WantItem>[],futures=<FutureItem>[],goals=<GoalItem>[],milestones=<MilestoneItem>[],inbox=<InboxItem>[];
  final trash=<TrashEntry>[]; final rememberMeta=<String,DateTime>{}; SharedPreferences? _prefs; int _counter=100; String? _cloudUid; bool cloudReady=false,cloudBusy=false;String? cloudError;
  static Future<AppState> load()async{final s=AppState._();s._prefs=await SharedPreferences.getInstance();final raw=s._prefs!.getString('neru_memory_state');if(raw==null){s._seed();await s._save();}else{try{s._restore(jsonDecode(raw));}catch(_){s._seed();}}s._migrateLegacyTaskInbox();s._purgeTrash();return s;}
  String id()=>'${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
  void _seed(){tasks.addAll([MemoryTask(id:'t1',title:'Shortsを編集する',bucket:TaskBucket.today,goalId:'g2'),MemoryTask(id:'t2',title:'美容院を予約する',bucket:TaskBucket.today),MemoryTask(id:'t3',title:'DDR5価格を確認する',bucket:TaskBucket.soon)]);wants.add(WantItem(id:'w1',title:'PC更新',status:WantStatus.considering,budget:150000,waitingFor:'DDR5価格が落ち着いたら'));futures.addAll([FutureItem(id:'f1',title:'実家へ帰る',status:FutureStatus.planned,timing:'11月'),FutureItem(id:'f2',title:'温泉旅行',timing:'冬')]);goals.addAll([GoalItem(id:'g1',title:'バイクで日本一周',progress:.38,deadline:'2030年10月',why:'自分のバイクで日本を回り、写真として残す',nextAction:'バイク候補を3台まで絞る'),GoalItem(id:'g2',title:'YouTubeを成長させる',progress:.22,deadline:'継続',nextAction:'Shortsを1本編集する')]);}
  void _restore(Map<String,dynamic>j){themeMode=ThemeMode.values.byName(j['themeMode']??'light');tasks.addAll((j['tasks']as List? ??[]).map((e)=>MemoryTask.fromJson(Map<String,dynamic>.from(e))));wants.addAll((j['wants']as List? ??[]).map((e)=>WantItem.fromJson(Map<String,dynamic>.from(e))));futures.addAll((j['futures']as List? ??[]).map((e)=>FutureItem.fromJson(Map<String,dynamic>.from(e))));goals.addAll((j['goals']as List? ??[]).map((e)=>GoalItem.fromJson(Map<String,dynamic>.from(e))));milestones.addAll((j['milestones']as List? ??[]).map((e)=>MilestoneItem.fromJson(Map<String,dynamic>.from(e))));inbox.addAll((j['inbox']as List? ??[]).map((e)=>InboxItem.fromJson(Map<String,dynamic>.from(e))));trash.addAll((j['trash']as List? ??[]).map((e)=>TrashEntry.fromJson(Map<String,dynamic>.from(e))));
    final rm=Map<String,dynamic>.from(j['rememberMeta']??const {});
    for(final e in rm.entries){final d=DateTime.tryParse('${e.value}');if(d!=null)rememberMeta[e.key]=d;}
  }
  Map<String,dynamic> _snapshot()=>{'themeMode':themeMode.name,'tasks':tasks.map((e)=>e.toJson()).toList(),'wants':wants.map((e)=>e.toJson()).toList(),'futures':futures.map((e)=>e.toJson()).toList(),'goals':goals.map((e)=>e.toJson()).toList(),'milestones':milestones.map((e)=>e.toJson()).toList(),'inbox':inbox.map((e)=>e.toJson()).toList(),'trash':trash.map((e)=>e.toJson()).toList(),'rememberMeta':rememberMeta.map((k,v)=>MapEntry(k,v.toIso8601String())),'updatedAt':DateTime.now().toUtc().toIso8601String()};
  String exportJson()=>const JsonEncoder.withIndent('  ').convert(_snapshot());
  Future<void> _save() async {
    final d = _snapshot();
    await _prefs?.setString('neru_memory_state', jsonEncode(d));
    if (_cloudUid != null) {
      try {
        await CloudStore.instance.saveItemState(_cloudUid!, d);
        cloudError = null;
      } catch (e) {
        // Local data remains authoritative while offline. Firestore also queues
        // supported writes in its local cache. Never discard local edits here.
        cloudError = '$e';
      }
    }
  }
  void _changed(){notifyListeners();_save();if(!kIsWeb){AndroidWidgetBridge.instance.sync(this);}}
  void _migrateLegacyTaskInbox(){final old=tasks.where((t)=>t.bucket==TaskBucket.inbox).toList();if(old.isEmpty)return;for(final t in old){inbox.add(InboxItem(id:id(),text:t.title,createdAt:DateTime.now()));tasks.remove(t);}_save();}
  void _purgeTrash(){final cut=DateTime.now().subtract(const Duration(days:30));trash.removeWhere((x)=>x.deletedAt.isBefore(cut));}
  Future<void> connectCloud(String uid) async {
    if (_cloudUid == uid && cloudReady) return;
    _cloudUid = uid;
    cloudBusy = true;
    notifyListeners();
    try {
      await CloudStore.instance.migrateLegacyIfNeeded(uid);
      final remote = await CloudStore.instance.loadItemState(uid);
      _mergeRemote(remote);
      await CloudStore.instance.saveItemState(uid, _snapshot());
      await _prefs?.setString('neru_memory_state', jsonEncode(_snapshot()));
      cloudReady = true;
      cloudError = null;
    } catch (e) {
      // Offline startup must still enter the app using SharedPreferences.
      cloudError = '$e';
      cloudReady = true;
    }
    cloudBusy = false;
    notifyListeners();
  }

  DateTime _stamp(Map<String,dynamic> j) =>
      DateTime.tryParse('${j['updatedAt'] ?? j['createdAt'] ?? ''}') ?? DateTime(2000);

  List<T> _mergeById<T>(List<T> local, List<dynamic> raw, String Function(T) idOf,
      DateTime Function(T) stampOf, T Function(Map<String,dynamic>) parse) {
    final map = <String,T>{for (final x in local) idOf(x): x};
    for (final value in raw) {
      final json = Map<String,dynamic>.from(value as Map);
      final incoming = parse(json);
      final id = idOf(incoming);
      final current = map[id];
      if (current == null || _stamp(json).isAfter(stampOf(current))) map[id] = incoming;
    }
    return map.values.toList();
  }

  void _mergeRemote(Map<String,dynamic> r) {
    final mt = _mergeById(tasks, r['tasks'] as List? ?? const [], (x)=>x.id,
        (x)=>x.updatedAt, MemoryTask.fromJson); tasks..clear()..addAll(mt);
    final mw = _mergeById(wants, r['wants'] as List? ?? const [], (x)=>x.id,
        (x)=>x.updatedAt, WantItem.fromJson); wants..clear()..addAll(mw);
    final mf = _mergeById(futures, r['futures'] as List? ?? const [], (x)=>x.id,
        (x)=>x.updatedAt, FutureItem.fromJson); futures..clear()..addAll(mf);
    final mg = _mergeById(goals, r['goals'] as List? ?? const [], (x)=>x.id,
        (x)=>x.updatedAt, GoalItem.fromJson); goals..clear()..addAll(mg);
    final mm = _mergeById(milestones, r['milestones'] as List? ?? const [], (x)=>x.id,
        (x)=>x.updatedAt, MilestoneItem.fromJson); milestones..clear()..addAll(mm);
    final mi = _mergeById(inbox, r['inbox'] as List? ?? const [], (x)=>x.id,
        (x)=>x.updatedAt, InboxItem.fromJson); inbox..clear()..addAll(mi);
    // Trash is append-only until purge/explicit permanent deletion.
    final trashMap = {for(final x in trash) x.id:x};
    for(final raw in (r['trash'] as List? ?? const [])) {
      final x=TrashEntry.fromJson(Map<String,dynamic>.from(raw as Map)); trashMap[x.id]=x;
    }
    trash..clear()..addAll(trashMap.values);
    final rm=Map<String,dynamic>.from(r['rememberMeta']??const {});
    for(final e in rm.entries){final d=DateTime.tryParse('${e.value}');if(d!=null)rememberMeta[e.key]=d;}
  }
  void disconnectCloud(){_cloudUid=null;cloudReady=false;notifyListeners();}void setTheme(ThemeMode m){themeMode=m;_changed();}
  void toggleTask(MemoryTask t){t.completed=!t.completed;t.updatedAt=DateTime.now();_changed();if(!kIsWeb)NotificationService.instance.syncTask(t);}void addTask(String x,{TaskBucket bucket=TaskBucket.soon}){tasks.insert(0,MemoryTask(id:id(),title:x,bucket:bucket));_changed();}void updateTask(MemoryTask x){x.updatedAt=DateTime.now();_changed();if(!kIsWeb)NotificationService.instance.syncTask(x);}
  void moveTaskToInbox(MemoryTask t){if(!kIsWeb)NotificationService.instance.cancelTask(t.id);inbox.insert(0,InboxItem(id:id(),text:t.title,createdAt:DateTime.now()));tasks.remove(t);_changed();}
  void deleteTask(MemoryTask x){if(!kIsWeb)NotificationService.instance.cancelTask(x.id);trash.insert(0,TrashEntry(id:id(),type:'task',title:x.title,data:x.toJson(),deletedAt:DateTime.now()));tasks.remove(x);_changed();}
  void addWant(String x){wants.insert(0,WantItem(id:id(),title:x));_changed();}void updateWant(WantItem x){x.updatedAt=DateTime.now();_changed();}void deleteWant(WantItem x){rememberMeta.remove(_rememberKey('want',x.id));trash.insert(0,TrashEntry(id:id(),type:'want',title:x.title,data:x.toJson(),deletedAt:DateTime.now()));wants.remove(x);_changed();}
  void addFuture(String x){futures.insert(0,FutureItem(id:id(),title:x));_changed();}void updateFuture(FutureItem x){x.updatedAt=DateTime.now();_changed();if(!kIsWeb)NotificationService.instance.syncFuture(x);}void deleteFuture(FutureItem x){rememberMeta.remove(_rememberKey('future',x.id));if(!kIsWeb)NotificationService.instance.cancelFuture(x.id);trash.insert(0,TrashEntry(id:id(),type:'future',title:x.title,data:x.toJson(),deletedAt:DateTime.now()));futures.remove(x);_changed();}
  void addGoal(String x){goals.insert(0,GoalItem(id:id(),title:x));_changed();}void updateGoal(GoalItem x){x.updatedAt=DateTime.now();_changed();}void deleteGoal(GoalItem x){rememberMeta.remove(_rememberKey('goal',x.id));trash.insert(0,TrashEntry(id:id(),type:'goal',title:x.title,data:x.toJson(),deletedAt:DateTime.now()));goals.remove(x);milestones.removeWhere((m)=>m.goalId==x.id);_changed();}
  void addMilestone(String gid,String x){milestones.add(MilestoneItem(id:id(),goalId:gid,title:x));_syncGoalFromMilestones(gid);_changed();}
  void updateMilestone(MilestoneItem x){x.updatedAt=DateTime.now();_syncGoalFromMilestones(x.goalId);_changed();}
  void deleteMilestone(MilestoneItem x){final gid=x.goalId;milestones.remove(x);_syncGoalFromMilestones(gid);_changed();}
  void _syncGoalFromMilestones(String gid){
    final ms=milestones.where((m)=>m.goalId==gid).toList();
    if(ms.isEmpty)return;
    final total=ms.fold<double>(0,(v,m)=>v+m.weight);
    if(total<=0)return;
    final value=ms.fold<double>(0,(v,m)=>v+(m.progress*m.weight))/total;
    for(final g in goals){
      if(g.id==gid){g.progress=value.clamp(0.0,1.0);g.updatedAt=DateTime.now();break;}
    }
  }
  void addInbox(String x){inbox.insert(0,InboxItem(id:id(),text:x,createdAt:DateTime.now()));_changed();}void deleteInbox(InboxItem x){inbox.remove(x);_changed();}
  void convertInbox(InboxItem x,String type){if(type=='task')tasks.insert(0,MemoryTask(id:id(),title:x.text,bucket:TaskBucket.soon));if(type=='want')wants.insert(0,WantItem(id:id(),title:x.text));if(type=='future')futures.insert(0,FutureItem(id:id(),title:x.text));if(type=='goal')goals.insert(0,GoalItem(id:id(),title:x.text));inbox.remove(x);_changed();}
  void restoreTrash(TrashEntry x){try{if(x.type=='task')tasks.insert(0,MemoryTask.fromJson(x.data));if(x.type=='want')wants.insert(0,WantItem.fromJson(x.data));if(x.type=='future')futures.insert(0,FutureItem.fromJson(x.data));if(x.type=='goal')goals.insert(0,GoalItem.fromJson(x.data));trash.remove(x);_changed();for(final t in tasks){if(t.id==x.data['id'])if(!kIsWeb)NotificationService.instance.syncTask(t);}
for(final f in futures){if(f.id==x.data['id'])if(!kIsWeb)NotificationService.instance.syncFuture(f);}}catch(_){}}void deleteTrashForever(TrashEntry x){trash.remove(x);_changed();}

  String _rememberKey(String type,String itemId)=>'$type:$itemId';

  RememberSuggestion? get rememberSuggestion {
    final now=DateTime.now();
    final candidates=<RememberSuggestion>[];

    void add(String type,String itemId,String title,DateTime updated,String reason){
      final key=_rememberKey(type,itemId);
      final last=rememberMeta[key];
      if(last!=null&&last.isAfter(now))return;
      final base=last!=null&&last.isAfter(updated)?last:updated;
      final age=now.difference(base).inDays;
      if(age<7)return;
      candidates.add(RememberSuggestion(
        type:type,id:itemId,title:title,reason:reason,ageDays:age,
      ));
    }

    for(final w in wants){
      if(w.status==WantStatus.purchased||w.status==WantStatus.dropped)continue;
      final reason=w.waitingFor.isNotEmpty
          ? '「${w.waitingFor}」のまま止まっています'
          : w.timing.isNotEmpty?'${w.timing} · 最近見返していません':'買いたいものを再確認';
      add('want',w.id,w.title,w.updatedAt,reason);
    }
    for(final f in futures){
      if(f.status==FutureStatus.completed||f.status==FutureStatus.dropped)continue;
      if(f.scheduledAt!=null)continue;
      add('future',f.id,f.title,f.updatedAt,'${f.timing} · 日時未定のままです');
    }
    for(final g in goals){
      if(g.status!=GoalStatus.active)continue;
      final reason=g.nextAction.isNotEmpty
          ? '次の行動: ${g.nextAction}'
          : '進め方を一度見直してみる';
      add('goal',g.id,g.title,g.updatedAt,reason);
    }
    if(candidates.isEmpty)return null;
    candidates.sort((a,b)=>b.ageDays.compareTo(a.ageDays));
    return candidates.first;
  }

  void rememberLater(RememberSuggestion item,{int days=7}){
    rememberMeta[_rememberKey(item.type,item.id)]=DateTime.now().add(Duration(days:days));
    _changed();
  }

  void rememberReviewed(RememberSuggestion item){
    rememberMeta[_rememberKey(item.type,item.id)]=DateTime.now();
    _changed();
  }

  void rememberHide(RememberSuggestion item){
    rememberMeta[_rememberKey(item.type,item.id)]=DateTime.now().add(const Duration(days:30));
    _changed();
  }

  Object? rememberItem(RememberSuggestion item){
    if(item.type=='want')return wants.cast<WantItem?>().firstWhere((x)=>x?.id==item.id,orElse:()=>null);
    if(item.type=='future')return futures.cast<FutureItem?>().firstWhere((x)=>x?.id==item.id,orElse:()=>null);
    if(item.type=='goal')return goals.cast<GoalItem?>().firstWhere((x)=>x?.id==item.id,orElse:()=>null);
    return null;
  }
}
class AppStateScope extends InheritedNotifier<AppState>{const AppStateScope({super.key,required AppState notifier,required super.child}):super(notifier:notifier);static AppState of(BuildContext c)=>c.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;}
