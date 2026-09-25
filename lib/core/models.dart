enum TaskBucket { inbox, today, soon, someday }
enum WantStatus { interested, considering, planned, purchased, dropped }
enum FutureStatus { considering, planned, scheduled, completed, dropped }
enum GoalStatus { active, achieved, paused, dropped }

class MemoryTask {
  MemoryTask({required this.id, required this.title, this.bucket=TaskBucket.inbox, this.completed=false,
    this.deadline, this.note='', this.goalId});
  final String id; String title; TaskBucket bucket; bool completed; DateTime? deadline; String note; String? goalId;
}
class WantItem {
  WantItem({required this.id, required this.title, this.status=WantStatus.interested, this.budget,
    this.timing='', this.waitingFor='', this.note=''});
  final String id; String title; WantStatus status; double? budget; String timing; String waitingFor; String note;
}
class FutureItem {
  FutureItem({required this.id, required this.title, this.status=FutureStatus.considering,
    this.timing='いつか', this.note=''});
  final String id; String title; FutureStatus status; String timing; String note;
}
class GoalItem {
  GoalItem({required this.id, required this.title, this.progress=0, this.deadline='', this.why='', this.nextAction=''});
  final String id; String title; double progress; String deadline; String why; String nextAction;
}
class InboxItem { InboxItem({required this.id, required this.text, required this.createdAt}); final String id; String text; DateTime createdAt; }
