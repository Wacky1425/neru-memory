import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';

/// A non-secret index only. Credentials are kept in Google Password Manager.
class PasswordIndexPage extends StatefulWidget {
  const PasswordIndexPage({super.key});
  @override State<PasswordIndexPage> createState()=>_PasswordIndexPageState();
}
class _PasswordIndexPageState extends State<PasswordIndexPage> {
  static const key='password_index_v1';
  static const categories=['銀行','個人アカウント','クレジットカード','仕事','ショッピング','SNS','その他'];
  final search=TextEditingController();
  List<SimpleEntry> items=[];
  String filter='すべて';
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
    String category=old?.category??categories[1];
    final result=await showDialog<bool>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,update)=>AlertDialog(
      title:Text(index==null?'サイトを分類に追加':'登録情報を編集'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('パスワードや認証コードは入力しないでください。実際のログイン情報はGoogleで管理します。'),
        const SizedBox(height:12),
        TextField(controller:title,decoration:const InputDecoration(labelText:'サイト・サービス名')),
        DropdownButtonFormField<String>(initialValue:category,isExpanded:true,
          items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
          onChanged:(x)=>update(()=>category=x??category)),
        TextField(controller:note,decoration:const InputDecoration(labelText:'メモ（秘密情報は不可）')),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('キャンセル')),
        FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('保存')),
      ],
    )));
    if(result==true&&title.text.trim().isNotEmpty){
      setState((){
        final value={'title':title.text.trim(),'category':category,'note':note.text.trim()};
        if(index==null){items.add(value);}else{items[index]=value;}
      });
      await _save();
    }
    title.dispose();note.dispose();
  }
  Future<void> _remove(int index)async{
    final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('一覧から削除しますか？'),
      content:const Text('Neru Memory内の分類情報だけを削除します。Googleに保存したパスワードは削除されません。'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('キャンセル')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('削除'))]));
    if(confirmed==true){AppStateScope.of(context).removeEntry('accountIndex',items[index]);await _save();}
  }
  @override Widget build(BuildContext context){
    final q=search.text.trim().toLowerCase();
    final shown=items.asMap().entries.where((e)=>(filter=='すべて'||e.value.category==filter)&&
      (q.isEmpty||[e.value.title,e.value.category,e.value.note].any((v)=>v.toLowerCase().contains(q)))).toList();
    return Scaffold(
      appBar:AppBar(title:const Text('パスワード管理'),actions:[
        IconButton(tooltip:'Googleで管理',icon:const Icon(Icons.open_in_new),onPressed:_openManager),
      ]),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('分類に追加')),
      body:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('パスワード本体はGoogleに保存',style:TextStyle(fontWeight:FontWeight.bold)),
          const SizedBox(height:6),
          const Text('ここではサイト名を銀行・個人アカウント・クレカなどに分類します。ID・パスワード・復旧コードは保存しません。'),
          const SizedBox(height:8),
          FilledButton.icon(onPressed:_openManager,icon:const Icon(Icons.key),label:const Text('Google パスワード マネージャーを開く')),
          const SizedBox(height:6),
          const Text('※ 分類一覧はNeru Memoryのクラウド同期対象です。秘密情報は入力しないでください。',style:TextStyle(fontSize:12)),
        ]))),
        const SizedBox(height:12),
        TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'サイト名・分類で検索',border:OutlineInputBorder())),
        const SizedBox(height:12),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
          for(final x in ['すべて',...categories])Padding(padding:const EdgeInsets.only(right:6),child:ChoiceChip(label:Text(x),selected:filter==x,onSelected:(_)=>setState(()=>filter=x))),
        ])),
        const SizedBox(height:8),
        if(shown.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('この分類に登録されたサイトはありません。')),
        for(final entry in shown)Card(child:ListTile(
          leading:const Icon(Icons.language),
          title:Text(entry.value.title),
          subtitle:Text([entry.value.category,entry.value.note].where((x)=>x!=null&&x.isNotEmpty).join(' · ')),
          onTap:()=>_edit(entry.key),
          trailing:PopupMenuButton<String>(onSelected:(v){if(v=='delete')_remove(entry.key);else _openManager();},
            itemBuilder:(_)=>const[PopupMenuItem(value:'open',child:Text('Googleで開く')),PopupMenuItem(value:'delete',child:Text('分類から削除'))]),
        )),
      ]),
    );
  }
}      final state=AppStateScope.of(context);
      state.saveEntry('accountIndex',SimpleEntry(id:old?.id??state.id(),title:title.text.trim(),category:category,note:note.text.trim()));
      await _save();
    }
    title.dispose();note.dispose();
  }
  Future<void> _remove(int index)async{
    final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('一覧から削除しますか？'),
      content:const Text('Neru Memory内の分類情報だけを削除します。Googleに保存したパスワードは削除されません。'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('キャンセル')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('削除'))]));
    if(confirmed==true){setState(()=>items.removeAt(index));await _save();}
  }
  @override Widget build(BuildContext context){
    final q=search.text.trim().toLowerCase();
    final shown=items.asMap().entries.where((e)=>(filter=='すべて'||e.value['category']==filter)&&
      (q.isEmpty||e.value.values.any((v)=>v.toLowerCase().contains(q)))).toList();
    return Scaffold(
      appBar:AppBar(title:const Text('パスワード管理'),actions:[
        IconButton(tooltip:'Googleで管理',icon:const Icon(Icons.open_in_new),onPressed:_openManager),
      ]),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('分類に追加')),
      body:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('パスワード本体はGoogleに保存',style:TextStyle(fontWeight:FontWeight.bold)),
          const SizedBox(height:6),
          const Text('ここではサイト名を銀行・個人アカウント・クレカなどに分類します。ID・パスワード・復旧コードは保存しません。'),
          const SizedBox(height:8),
          FilledButton.icon(onPressed:_openManager,icon:const Icon(Icons.key),label:const Text('Google パスワード マネージャーを開く')),
          const SizedBox(height:6),
          const Text('※ 分類一覧はこの端末内にのみ保存され、他端末へ同期されません。',style:TextStyle(fontSize:12)),
        ]))),
        const SizedBox(height:12),
        TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'サイト名・分類で検索',border:OutlineInputBorder())),
        const SizedBox(height:12),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
          for(final x in ['すべて',...categories])Padding(padding:const EdgeInsets.only(right:6),child:ChoiceChip(label:Text(x),selected:filter==x,onSelected:(_)=>setState(()=>filter=x))),
        ])),
        const SizedBox(height:8),
        if(shown.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('この分類に登録されたサイトはありません。')),
        for(final entry in shown)Card(child:ListTile(
          leading:const Icon(Icons.language),
          title:Text(entry.value['title']??''),
          subtitle:Text([entry.value['category'],entry.value['note']].where((x)=>x!=null&&x.isNotEmpty).join(' · ')),
          onTap:()=>_edit(entry.key),
          trailing:PopupMenuButton<String>(onSelected:(v){if(v=='delete')_remove(entry.key);else _openManager();},
            itemBuilder:(_)=>const[PopupMenuItem(value:'open',child:Text('Googleで開く')),PopupMenuItem(value:'delete',child:Text('分類から削除'))]),
        )),
      ]),
    );
  }
}
