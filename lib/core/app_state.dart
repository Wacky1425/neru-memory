import 'package:flutter/material.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  final List<MemoryTask> tasks=[]; final List<WantItem> wants=[]; final List<FutureItem> futures=[];
  final List<GoalItem> goals=[]; final List<InboxItem> inbox=[];
  int _counter=100;
  String id() => '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
  AppState.seeded() {
    tasks.addAll([
      MemoryTask(id:'t1',title:'Shortsを編集する',bucket:TaskBucket.today,goalId:'g2'),
      MemoryTask(id:'t2',title:'美容院を予約する',bucket:TaskBucket.today),
      MemoryTask(id:'t3',title:'DDR5価格を確認する',bucket:TaskBucket.soon),
      MemoryTask(id:'t4',title:'草野球チームを探す',bucket:TaskBucket.someday,goalId:'g3'),
    ]);
    wants.addAll([WantItem(id:'w1',title:'PC更新',status:WantStatus.considering,budget:150000,waitingFor:'DDR5価格が落ち着いたら'), WantItem(id:'w2',title:'バイク',status:WantStatus.planned,budget:500000,timing:'数年以内')]);
    futures.addAll([FutureItem(id:'f1',title:'実家へ帰る',status:FutureStatus.planned,timing:'11月'),FutureItem(id:'f2',title:'温泉旅行',status:FutureStatus.considering,timing:'冬')]);
    goals.addAll([GoalItem(id:'g1',title:'バイクで日本一周',progress:.38,deadline:'2030年10月',why:'自分のバイクで日本を回り、写真として残す',nextAction:'バイク候補を3台まで絞る'),GoalItem(id:'g2',title:'YouTubeを成長させる',progress:.22,deadline:'継続',nextAction:'Shortsを1本編集する'),GoalItem(id:'g3',title:'草野球で限界球速に挑戦',progress:.08,deadline:'いつか',nextAction:'近くの草野球チームを探す')]);
  }
  void setTheme(ThemeMode mode){themeMode=mode;notifyListeners();}
  void toggleTask(MemoryTask task){task.completed=!task.completed;notifyListeners();}
  void addTask(String title,{TaskBucket bucket=TaskBucket.inbox}){tasks.insert(0,MemoryTask(id:id(),title:title,bucket:bucket));notifyListeners();}
  void addWant(String title){wants.insert(0,WantItem(id:id(),title:title));notifyListeners();}
  void addFuture(String title){futures.insert(0,FutureItem(id:id(),title:title));notifyListeners();}
  void addGoal(String title){goals.insert(0,GoalItem(id:id(),title:title));notifyListeners();}
  void addInbox(String text){inbox.insert(0,InboxItem(id:id(),text:text,createdAt:DateTime.now()));notifyListeners();}
}
class AppStateScope extends InheritedNotifier<AppState>{const AppStateScope({super.key,required AppState notifier,required super.child}):super(notifier:notifier); static AppState of(BuildContext context)=>context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;}
