class TrashEntry {
  TrashEntry({required this.id,required this.type,required this.title,required this.data,required this.deletedAt});
  final String id,type,title; final Map<String,dynamic> data; final DateTime deletedAt;
  Map<String,dynamic> toJson()=>{'id':id,'type':type,'title':title,'data':data,'deletedAt':deletedAt.toIso8601String()};
  factory TrashEntry.fromJson(Map<String,dynamic> j)=>TrashEntry(id:j['id'],type:j['type'],title:j['title'],data:Map<String,dynamic>.from(j['data']??{}),deletedAt:DateTime.parse(j['deletedAt']));
}
