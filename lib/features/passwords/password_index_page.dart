import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';

/// Account entries, including passwords, sync through the existing Firestore account index.
class PasswordIndexPage extends StatefulWidget {
  const PasswordIndexPage({super.key});
  @override State<PasswordIndexPage> createState()=>_PasswordIndexPageState();
}
class _PasswordIndexPageState extends State<PasswordIndexPage> {
  static const key='password_index_v1';
  static const categoryPrefix='__neru_category__:';
  static const categories=['銀行','個人アカウント','クレジットカード','仕事','ショッピング','SNS','その他'];
  final search=TextEditingController();
  List<SimpleEntry> items=[];
  static const passwordKey='neru_local_passwords_v1';
  String filter='すべて';
  bool _isCategoryMarker(SimpleEntry e)=>e.id.startsWith(categoryPrefix);
  List<String> get allCategories=>{
    ...categories,
    ...items.where(_isCategoryMarker).map((e)=>e.title),
    ...items.where((e)=>!_isCategoryMarker(e)&&e.category.isNotEmpty).map((e)=>e.category),
  }.toList();
  Future<String?> _newCategory()async{
    final name=TextEditingController();
    final result=await showDialog<String>(context:context,builder:(d)=>AlertDialog(
      title:const Text('カテゴリを追加'),
      content:TextField(controller:name,autofocus:true,maxLength:30,decoration:const InputDecoration(labelText:'カテゴリ名',hintText:'例：ゲーム・配信活動')),
      actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('キャンセル')),
        FilledButton(onPressed:()=>Navigator.pop(d,name.text.trim()),child:const Text('追加'))],
    ));
    name.dispose();
    if(result==null||result.isEmpty)return null;
    if(allCategories.contains(result)){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('同じ名前のカテゴリが既にあります')));
      return result;
    }
    final state=AppStateScope.of(context);
    state.saveEntry('accountIndex',SimpleEntry(id:'$categoryPrefix${state.id()}',title:result));
    await _save();
    return result;
  }
  @override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)_load();});}
  @override void dispose(){search.dispose();super.dispose();}
  Future<void> _load()async{
    final state=AppStateScope.of(context);
    final p=await SharedPreferences.getInstance();
    try {
      final data=jsonDecode(p.getString(key)??'[]') as List;
      for(final raw in data){
        final x=Map<String,String>.from(raw as Map);
        if(!state.accountIndex.any((e)=>e.title==x['title']&&e.category==x['category'])){
          state.saveEntry('accountIndex',SimpleEntry(id:state.id(),title:x['title']??'',category:x['category']??'',note:x['note']??''));
        }
      }
      if(data.isNotEmpty)await p.remove(key);
    }catch(_){}
    try {
      final saved=jsonDecode(p.getString(passwordKey)??'{}') as Map;
      final legacy=Map<String,String>.from(saved);
      for(final entry in state.accountIndex){
        final value=legacy[entry.id];
        if(value!=null && value.isNotEmpty && entry.password.isEmpty){
          state.saveEntry('accountIndex',SimpleEntry(id:entry.id,title:entry.title,category:entry.category,note:entry.note,password:value,loginId:entry.loginId,url:entry.url));
        }
      }
      if(legacy.isNotEmpty)await p.remove(passwordKey);
    } catch (_) {}
    if(mounted)setState(()=>items=state.accountIndex);
  }
  Future<void> _save()async{if(mounted)setState(()=>items=AppStateScope.of(context).accountIndex);}
  Future<void> _openManager()async{
    final ok=await launchUrl(Uri.parse('https://passwords.google.com/'),mode:LaunchMode.externalApplication);
    if(!ok&&mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Google パスワード マネージャーを開けませんでした')));
  }
  Future<void> _edit([int? index])async{
    final old=index==null?null:items[index];
    final title=TextEditingController(text:old?.title??'');
    final note=TextEditingController(text:old?.note??'');
    final loginId=TextEditingController(text:old?.loginId??'');
    final url=TextEditingController(text:old?.url??'');
    final password=TextEditingController(text:old==null?'':old.password);
    var visible=false;
    String category=old?.category??categories[1];
    final choices=<String>{...allCategories,category}.toList();
    final result=await showDialog<bool>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,update)=>AlertDialog(
      title:Text(index==null?'サイトを分類に追加':'登録情報を編集'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('パスワードはFirebase経由でWeb・Android間に同期されます。現在は暗号化されず保存されるため、重要なパスワードの登録は推奨しません。',style:TextStyle(fontSize:12)),
        const SizedBox(height:12),
        TextField(controller:title,decoration:const InputDecoration(labelText:'サイト・サービス名')),
        Row(children:[
          Expanded(child:DropdownButtonFormField<String>(key:ValueKey(category),initialValue:category,isExpanded:true,
            items:choices.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(x)=>update(()=>category=x??category))),
          IconButton(tooltip:'新しいカテゴリを追加',icon:const Icon(Icons.create_new_folder_outlined),onPressed:()async{
            final added=await _newCategory();
            if(added!=null){update((){if(!choices.contains(added))choices.add(added);category=added;});}
          }),
        ]),
        TextField(controller:loginId,decoration:const InputDecoration(labelText:'ログインID・メールアドレス')),
        TextField(controller:url,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'ログインURL（任意）')),
        TextField(controller:note,maxLines:2,decoration:const InputDecoration(labelText:'メモ')),
        TextField(controller:password,obscureText:!visible,decoration:InputDecoration(labelText:'パスワード（端末間で同期）',suffixIcon:IconButton(icon:Icon(visible?Icons.visibility_off:Icons.visibility),onPressed:()=>update(()=>visible=!visible)))),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('キャンセル')),
        FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('保存')),
      ],
    )));
    if(result==true&&title.text.trim().isNotEmpty){
      final state=AppStateScope.of(context);
      final id=old?.id??state.id();
      state.saveEntry('accountIndex',SimpleEntry(id:id,title:title.text.trim(),category:category,note:note.text.trim(),password:password.text,loginId:loginId.text.trim(),url:url.text.trim()));
      await _save();
    }
    title.dispose();note.dispose();password.dispose();loginId.dispose();url.dispose();
  }
  Future<void> _remove(int index)async{
    final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('一覧から削除しますか？'),
      content:const Text('このアカウント情報と登録パスワードを同期先から削除します。'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('キャンセル')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('削除'))]));
    if(confirmed==true){
      AppStateScope.of(context).removeEntry('accountIndex',items[index]);
      await _save();
    }
  }
  String _csvCell(String value)=>'"${value.replaceAll('"','""')}"';
  Future<void> _exportCsv()async{
    final state=AppStateScope.of(context);
    final rows=<List<String>>[
      ['サービス名','ログインID','パスワード','分類','URL','メモ','更新日時'],
      for(final x in state.accountIndex.where((e)=>!_isCategoryMarker(e)))[x.title,x.loginId,x.password,x.category,x.url,x.note,x.updatedAt.toIso8601String()],
    ];
    final csv='\uFEFF${rows.map((r)=>r.map(_csvCell).join(',')).join('\r\n')}';
    await Clipboard.setData(ClipboardData(text:csv));
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('CSVをコピーしました。テキストファイルに保存してGoogle Driveへアップロードできます。')));
  }
  Future<void> _copy(String value,String label)async{
    await Clipboard.setData(ClipboardData(text:value));
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$labelをコピーしました')));
  }
  @override Widget build(BuildContext context){
    final q=search.text.trim().toLowerCase();
    final shown=items.asMap().entries.where((e)=>!_isCategoryMarker(e.value)&&(filter=='すべて'||e.value.category==filter)&&
      (q.isEmpty||[e.value.title,e.value.category,e.value.loginId,e.value.url,e.value.note].any((v)=>v.toLowerCase().contains(q)))).toList();
    final grouped=<String,List<MapEntry<int,SimpleEntry>>>{};
    for(final e in shown){(grouped[e.value.category.isEmpty?'その他':e.value.category]??=[]).add(e);}
    return Scaffold(
      appBar:AppBar(title:Text('パスワード管理 (${items.where((e)=>!_isCategoryMarker(e)).length})'),actions:[
        IconButton(tooltip:'カテゴリを追加',icon:const Icon(Icons.create_new_folder_outlined),onPressed:_newCategory),
        IconButton(tooltip:'CSVバックアップをコピー',icon:const Icon(Icons.download_outlined),onPressed:_exportCsv),
      ]),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('アカウントを追加')),
      body:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('パスワードを直接登録できます',style:TextStyle(fontWeight:FontWeight.bold)),
          const SizedBox(height:6),
          const Text('サービス名・ログインID・パスワードを分類して管理。IDとパスワードは一覧からコピーできます。'),
          const SizedBox(height:8),
          OutlinedButton.icon(onPressed:_exportCsv,icon:const Icon(Icons.download_outlined),label:const Text('CSVバックアップをコピー')),
          const SizedBox(height:6),
          const Text('注意：Firebase保存・CSV出力は暗号化されません。CSVは他人に渡さず安全に保管してください。',style:TextStyle(fontSize:12)),
        ]))),
        const SizedBox(height:12),
        TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'サイト名・分類で検索',border:OutlineInputBorder())),
        const SizedBox(height:12),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
          for(final x in ['すべて',...allCategories])Padding(padding:const EdgeInsets.only(right:6),child:ChoiceChip(label:Text(x),selected:filter==x,onSelected:(_)=>setState(()=>filter=x))),
        ])),
        const SizedBox(height:8),
        if(shown.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('この分類に登録されたサイトはありません。')),
        for(final category in allCategories)
          if(grouped.containsKey(category))...[ 
            Padding(padding:const EdgeInsets.fromLTRB(4,16,4,6),child:Text('$category  ${grouped[category]!.length}件',style:Theme.of(context).textTheme.titleSmall)),
            for(final entry in grouped[category]!)Card(child:ListTile(
              leading:CircleAvatar(child:Text(entry.value.title.isEmpty?'?':entry.value.title.substring(0,1))),
              title:Text(entry.value.title,style:const TextStyle(fontWeight:FontWeight.w600)),
              subtitle:Text([entry.value.loginId,entry.value.note].where((x)=>x.isNotEmpty).join(' · '),maxLines:2,overflow:TextOverflow.ellipsis),
              onTap:()=>_edit(entry.key),
              trailing:Row(mainAxisSize:MainAxisSize.min,children:[
                if(entry.value.loginId.isNotEmpty)IconButton(tooltip:'IDをコピー',icon:const Icon(Icons.person_outline),onPressed:()=>_copy(entry.value.loginId,'ID')),
                if(entry.value.password.isNotEmpty)IconButton(tooltip:'パスワードをコピー',icon:const Icon(Icons.copy_outlined),onPressed:()=>_copy(entry.value.password,'パスワード')),
                PopupMenuButton<String>(onSelected:(v){
                  if(v=='delete'){_remove(entry.key);}else if(v=='open'){
                    final u=Uri.tryParse(entry.value.url);
                    if(u!=null&&(u.scheme=='https'||u.scheme=='http'))launchUrl(u,mode:LaunchMode.externalApplication);
                  }else{_edit(entry.key);}
                },itemBuilder:(_)=>[
                  const PopupMenuItem(value:'edit',child:Text('編集')),
                  if(entry.value.url.isNotEmpty)const PopupMenuItem(value:'open',child:Text('サイトを開く')),
                  const PopupMenuItem(value:'delete',child:Text('削除')),
                ]),
              ]),
            )),
          ],
      ]),
    );
  }
}
