enum TaskBucket { inbox, today, soon, someday }
enum WantStatus { interested, considering, planned, purchased, dropped }
enum FutureStatus { considering, planned, scheduled, completed, dropped }
enum GoalStatus { active, achieved, paused, dropped }

class MemoryTask {
  MemoryTask({required this.id,required this.title,this.bucket=TaskBucket.soon,this.completed=false,this.deadline,this.note='',this.goalId,List<String>? tags}) : tags=tags??[];
  final String id; String title; TaskBucket bucket; bool completed; DateTime? deadline; String note; String? goalId; List<String> tags;
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'bucket':bucket.name,'completed':completed,'deadline':deadline?.toIso8601String(),'note':note,'goalId':goalId,'tags':tags};
  factory MemoryTask.fromJson(Map<String,dynamic> j)=>MemoryTask(id:j['id'],title:j['title'],bucket:TaskBucket.values.byName(j['bucket']??'soon'),completed:j['completed']??false,deadline:j['deadline']==null?null:DateTime.tryParse(j['deadline']),note:j['note']??'',goalId:j['goalId'],tags:List<String>.from(j['tags']??const []));
}
class WantItem {
  WantItem({required this.id,required this.title,this.status=WantStatus.interested,this.budget,this.timing='',this.waitingFor='',this.note='',List<String>? tags,DateTime? updatedAt}) : tags=tags??[], updatedAt=updatedAt??DateTime.now();
  final String id; String title; WantStatus status; double? budget; String timing,waitingFor,note; List<String> tags; DateTime updatedAt;
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'status':status.name,'budget':budget,'timing':timing,'waitingFor':waitingFor,'note':note,'tags':tags,'updatedAt':updatedAt.toIso8601String()};
  factory WantItem.fromJson(Map<String,dynamic> j)=>WantItem(id:j['id'],title:j['title'],status:WantStatus.values.byName(j['status']??'interested'),budget:(j['budget']as num?)?.toDouble(),timing:j['timing']??'',waitingFor:j['waitingFor']??'',note:j['note']??'',tags:List<String>.from(j['tags']??const []),updatedAt:j['updatedAt']==null?DateTime(2000):DateTime.tryParse(j['updatedAt'])??DateTime(2000));
}
class FutureItem {
  FutureItem({required this.id,required this.title,this.status=FutureStatus.considering,this.timing='いつか',this.note='',this.scheduledAt,this.googleEventId,List<String>? tags,DateTime? updatedAt}) : tags=tags??[], updatedAt=updatedAt??DateTime.now();
  final String id; String title; FutureStatus status; String timing,note; DateTime? scheduledAt; String? googleEventId; List<String> tags; DateTime updatedAt;
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'status':status.name,'timing':timing,'note':note,'scheduledAt':scheduledAt?.toIso8601String(),'googleEventId':googleEventId,'tags':tags,'updatedAt':updatedAt.toIso8601String()};
  factory FutureItem.fromJson(Map<String,dynamic> j)=>FutureItem(id:j['id'],title:j['title'],status:FutureStatus.values.byName(j['status']??'considering'),timing:j['timing']??'いつか',note:j['note']??'',scheduledAt:j['scheduledAt']==null?null:DateTime.tryParse(j['scheduledAt']),googleEventId:j['googleEventId'],tags:List<String>.from(j['tags']??const []),updatedAt:j['updatedAt']==null?DateTime(2000):DateTime.tryParse(j['updatedAt'])??DateTime(2000));
}
class MilestoneItem {
  MilestoneItem({required this.id,required this.goalId,required this.title,this.progress=0,this.weight=1,this.note=''});
  final String id,goalId; String title,note; double progress,weight;
  Map<String,dynamic> toJson()=>{'id':id,'goalId':goalId,'title':title,'progress':progress,'weight':weight,'note':note};
  factory MilestoneItem.fromJson(Map<String,dynamic> j)=>MilestoneItem(id:j['id'],goalId:j['goalId'],title:j['title'],progress:(j['progress']as num? ??0).toDouble(),weight:(j['weight']as num? ??1).toDouble(),note:j['note']??'');
}
class GoalItem {
  GoalItem({required this.id,required this.title,this.progress=0,this.deadline='',this.deadlineDate,this.why='',this.nextAction='',this.status=GoalStatus.active,List<String>? tags,DateTime? updatedAt}) : tags=tags??[], updatedAt=updatedAt??DateTime.now();
  final String id; String title; double progress; String deadline,why,nextAction; DateTime? deadlineDate; GoalStatus status; List<String> tags; DateTime updatedAt;
  String get deadlineLabel=>deadlineDate==null?deadline:'${deadlineDate!.year}/${deadlineDate!.month}/${deadlineDate!.day}';
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'progress':progress,'deadline':deadline,'deadlineDate':deadlineDate?.toIso8601String(),'why':why,'nextAction':nextAction,'status':status.name,'tags':tags,'updatedAt':updatedAt.toIso8601String()};
  factory GoalItem.fromJson(Map<String,dynamic> j)=>GoalItem(id:j['id'],title:j['title'],progress:(j['progress']as num? ??0).toDouble(),deadline:j['deadline']??'',deadlineDate:j['deadlineDate']==null?null:DateTime.tryParse(j['deadlineDate']),why:j['why']??'',nextAction:j['nextAction']??'',status:GoalStatus.values.byName(j['status']??'active'),tags:List<String>.from(j['tags']??const []),updatedAt:j['updatedAt']==null?DateTime(2000):DateTime.tryParse(j['updatedAt'])??DateTime(2000));
}
class InboxItem {
  InboxItem({required this.id,required this.text,required this.createdAt}); final String id; String text; DateTime createdAt;
  Map<String,dynamic> toJson()=>{'id':id,'text':text,'createdAt':createdAt.toIso8601String()};
  factory InboxItem.fromJson(Map<String,dynamic> j)=>InboxItem(id:j['id'],text:j['text'],createdAt:DateTime.parse(j['createdAt']));
}
