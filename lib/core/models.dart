enum TaskBucket { inbox, today, soon, someday }
enum WantStatus { interested, considering, planned, purchased, dropped }
enum FutureStatus { considering, planned, scheduled, completed, dropped }
enum GoalStatus { active, achieved, paused, dropped }

class MemoryTask {
  MemoryTask({required this.id, required this.title, this.bucket = TaskBucket.inbox, this.completed = false, this.deadline, this.note = '', this.goalId});
  final String id;
  String title;
  TaskBucket bucket;
  bool completed;
  DateTime? deadline;
  String note;
  String? goalId;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'bucket': bucket.name, 'completed': completed, 'deadline': deadline?.toIso8601String(), 'note': note, 'goalId': goalId};
  factory MemoryTask.fromJson(Map<String, dynamic> j) => MemoryTask(id: j['id'], title: j['title'], bucket: TaskBucket.values.byName(j['bucket'] ?? 'inbox'), completed: j['completed'] ?? false, deadline: j['deadline'] == null ? null : DateTime.tryParse(j['deadline']), note: j['note'] ?? '', goalId: j['goalId']);
}

class WantItem {
  WantItem({required this.id, required this.title, this.status = WantStatus.interested, this.budget, this.timing = '', this.waitingFor = '', this.note = ''});
  final String id;
  String title;
  WantStatus status;
  double? budget;
  String timing;
  String waitingFor;
  String note;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'status': status.name, 'budget': budget, 'timing': timing, 'waitingFor': waitingFor, 'note': note};
  factory WantItem.fromJson(Map<String, dynamic> j) => WantItem(id: j['id'], title: j['title'], status: WantStatus.values.byName(j['status'] ?? 'interested'), budget: (j['budget'] as num?)?.toDouble(), timing: j['timing'] ?? '', waitingFor: j['waitingFor'] ?? '', note: j['note'] ?? '');
}

class FutureItem {
  FutureItem({required this.id, required this.title, this.status = FutureStatus.considering, this.timing = 'いつか', this.note = ''});
  final String id;
  String title;
  FutureStatus status;
  String timing;
  String note;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'status': status.name, 'timing': timing, 'note': note};
  factory FutureItem.fromJson(Map<String, dynamic> j) => FutureItem(id: j['id'], title: j['title'], status: FutureStatus.values.byName(j['status'] ?? 'considering'), timing: j['timing'] ?? 'いつか', note: j['note'] ?? '');
}

class MilestoneItem {
  MilestoneItem({required this.id, required this.goalId, required this.title, this.progress = 0, this.weight = 1, this.note = ''});
  final String id;
  final String goalId;
  String title;
  double progress;
  double weight;
  String note;
  Map<String, dynamic> toJson() => {'id': id, 'goalId': goalId, 'title': title, 'progress': progress, 'weight': weight, 'note': note};
  factory MilestoneItem.fromJson(Map<String, dynamic> j) => MilestoneItem(id: j['id'], goalId: j['goalId'], title: j['title'], progress: (j['progress'] as num? ?? 0).toDouble(), weight: (j['weight'] as num? ?? 1).toDouble(), note: j['note'] ?? '');
}

class GoalItem {
  GoalItem({required this.id, required this.title, this.progress = 0, this.deadline = '', this.why = '', this.nextAction = '', this.status = GoalStatus.active});
  final String id;
  String title;
  double progress;
  String deadline;
  String why;
  String nextAction;
  GoalStatus status;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'progress': progress, 'deadline': deadline, 'why': why, 'nextAction': nextAction, 'status': status.name};
  factory GoalItem.fromJson(Map<String, dynamic> j) => GoalItem(id: j['id'], title: j['title'], progress: (j['progress'] as num? ?? 0).toDouble(), deadline: j['deadline'] ?? '', why: j['why'] ?? '', nextAction: j['nextAction'] ?? '', status: GoalStatus.values.byName(j['status'] ?? 'active'));
}

class InboxItem {
  InboxItem({required this.id, required this.text, required this.createdAt});
  final String id;
  String text;
  DateTime createdAt;
  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'createdAt': createdAt.toIso8601String()};
  factory InboxItem.fromJson(Map<String, dynamic> j) => InboxItem(id: j['id'], text: j['text'], createdAt: DateTime.parse(j['createdAt']));
}
