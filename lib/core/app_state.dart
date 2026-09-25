import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'cloud_store.dart';

class AppState extends ChangeNotifier {
  AppState._();
  ThemeMode themeMode = ThemeMode.light;
  final List<MemoryTask> tasks = [];
  final List<WantItem> wants = [];
  final List<FutureItem> futures = [];
  final List<GoalItem> goals = [];
  final List<MilestoneItem> milestones = [];
  final List<InboxItem> inbox = [];
  SharedPreferences? _prefs;
  int _counter = 100;
  String? _cloudUid;
  bool cloudReady = false;
  bool cloudBusy = false;
  String? cloudError;

  static Future<AppState> load() async {
    final state = AppState._();
    state._prefs = await SharedPreferences.getInstance();
    final raw = state._prefs!.getString('neru_memory_state');
    if (raw == null) {
      state._seed();
      await state._save();
    } else {
      try { state._restore(jsonDecode(raw) as Map<String, dynamic>); } catch (_) { state._seed(); }
    }
    return state;
  }

  String id() => '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
  void _seed() {
    tasks.addAll([MemoryTask(id: 't1', title: 'Shortsを編集する', bucket: TaskBucket.today, goalId: 'g2'), MemoryTask(id: 't2', title: '美容院を予約する', bucket: TaskBucket.today), MemoryTask(id: 't3', title: 'DDR5価格を確認する', bucket: TaskBucket.soon)]);
    wants.add(WantItem(id: 'w1', title: 'PC更新', status: WantStatus.considering, budget: 150000, waitingFor: 'DDR5価格が落ち着いたら'));
    futures.addAll([FutureItem(id: 'f1', title: '実家へ帰る', status: FutureStatus.planned, timing: '11月'), FutureItem(id: 'f2', title: '温泉旅行', timing: '冬')]);
    goals.addAll([GoalItem(id: 'g1', title: 'バイクで日本一周', progress: .38, deadline: '2030年10月', why: '自分のバイクで日本を回り、写真として残す', nextAction: 'バイク候補を3台まで絞る'), GoalItem(id: 'g2', title: 'YouTubeを成長させる', progress: .22, deadline: '継続', nextAction: 'Shortsを1本編集する')]);
    milestones.addAll([MilestoneItem(id: 'm1', goalId: 'g1', title: 'バイクを決める', progress: 1), MilestoneItem(id: 'm2', goalId: 'g1', title: '資金を貯める', progress: .4), MilestoneItem(id: 'm3', goalId: 'g1', title: 'ルートを決める', progress: .2)]);
  }

  void _restore(Map<String, dynamic> j) {
    themeMode = ThemeMode.values.byName(j['themeMode'] ?? 'light');
    tasks.addAll((j['tasks'] as List? ?? []).map((e) => MemoryTask.fromJson(Map<String, dynamic>.from(e))));
    wants.addAll((j['wants'] as List? ?? []).map((e) => WantItem.fromJson(Map<String, dynamic>.from(e))));
    futures.addAll((j['futures'] as List? ?? []).map((e) => FutureItem.fromJson(Map<String, dynamic>.from(e))));
    goals.addAll((j['goals'] as List? ?? []).map((e) => GoalItem.fromJson(Map<String, dynamic>.from(e))));
    milestones.addAll((j['milestones'] as List? ?? []).map((e) => MilestoneItem.fromJson(Map<String, dynamic>.from(e))));
    inbox.addAll((j['inbox'] as List? ?? []).map((e) => InboxItem.fromJson(Map<String, dynamic>.from(e))));
  }

  Map<String, dynamic> _snapshot() => {'themeMode': themeMode.name, 'tasks': tasks.map((e) => e.toJson()).toList(), 'wants': wants.map((e) => e.toJson()).toList(), 'futures': futures.map((e) => e.toJson()).toList(), 'goals': goals.map((e) => e.toJson()).toList(), 'milestones': milestones.map((e) => e.toJson()).toList(), 'inbox': inbox.map((e) => e.toJson()).toList(), 'updatedAt': DateTime.now().toUtc().toIso8601String()};

  Future<void> _save() async {
    final data = _snapshot();
    await _prefs?.setString('neru_memory_state', jsonEncode(data));
    final uid = _cloudUid;
    if (uid != null) {
      try { await CloudStore.instance.saveState(uid, data); cloudError = null; }
      catch (e) { cloudError = e.toString(); }
    }
  }
  void _changed() { notifyListeners(); _save(); }

  Future<void> connectCloud(String uid) async {
    if (_cloudUid == uid && cloudReady) return;
    _cloudUid = uid; cloudBusy = true; cloudError = null; notifyListeners();
    try {
      final remote = await CloudStore.instance.loadState(uid);
      if (remote == null) { await CloudStore.instance.saveState(uid, _snapshot()); }
      else {
        tasks.clear(); wants.clear(); futures.clear(); goals.clear(); milestones.clear(); inbox.clear();
        _restore(remote); await _prefs?.setString('neru_memory_state', jsonEncode(_snapshot()));
      }
      cloudReady = true;
    } catch (e) { cloudError = e.toString(); cloudReady = false; }
    cloudBusy = false; notifyListeners();
  }

  void disconnectCloud() { _cloudUid = null; cloudReady = false; cloudBusy = false; cloudError = null; notifyListeners(); }

  void setTheme(ThemeMode mode) { themeMode = mode; _changed(); }
  void toggleTask(MemoryTask task) { task.completed = !task.completed; _changed(); }
  void addTask(String title, {TaskBucket bucket = TaskBucket.inbox}) { tasks.insert(0, MemoryTask(id: id(), title: title, bucket: bucket)); _changed(); }
  void updateTask(MemoryTask item) => _changed();
  void deleteTask(MemoryTask item) { tasks.remove(item); _changed(); }
  void addWant(String title) { wants.insert(0, WantItem(id: id(), title: title)); _changed(); }
  void updateWant(WantItem item) => _changed();
  void deleteWant(WantItem item) { wants.remove(item); _changed(); }
  void addFuture(String title) { futures.insert(0, FutureItem(id: id(), title: title)); _changed(); }
  void updateFuture(FutureItem item) => _changed();
  void deleteFuture(FutureItem item) { futures.remove(item); _changed(); }
  void addGoal(String title) { goals.insert(0, GoalItem(id: id(), title: title)); _changed(); }
  void updateGoal(GoalItem item) => _changed();
  void deleteGoal(GoalItem item) { goals.remove(item); milestones.removeWhere((m) => m.goalId == item.id); _changed(); }
  void addMilestone(String goalId, String title) { milestones.add(MilestoneItem(id: id(), goalId: goalId, title: title)); _changed(); }
  void updateMilestone(MilestoneItem item) => _changed();
  void deleteMilestone(MilestoneItem item) { milestones.remove(item); _changed(); }
  void addInbox(String text) { inbox.insert(0, InboxItem(id: id(), text: text, createdAt: DateTime.now())); _changed(); }
  void deleteInbox(InboxItem item) { inbox.remove(item); _changed(); }
  void convertInbox(InboxItem item, String type) { if (type == 'task') addTask(item.text); if (type == 'want') addWant(item.text); if (type == 'future') addFuture(item.text); if (type == 'goal') addGoal(item.text); inbox.remove(item); _changed(); }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required AppState notifier, required super.child}) : super(notifier: notifier);
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;
}
