import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';

/// Account index synced via Firestore; passwords are stored only on this device.
class PasswordIndexPage extends StatefulWidget {
  const PasswordIndexPage({super.key});
  @override State<PasswordIndexPage> createState()=>_PasswordIndexPageState();
}
class _PasswordIndexPageState extends State<PasswordIndexPage> {
  static const key='password_index_v1';
  static const categories=['銀行','個人アカウント','クレジットカード','仕事','ショッピング','SNS','その他'];
  final search=TextEditingController();
  List<SimpleEntry> items=[];
  Map<String,String> localPasswords={};
  static const passwordKey='neru_local_passwords_v1';
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
    try {
      final saved=jsonDecode(p.getString(passwordKey)??'{}') as Map;
      localPasswords=Map<String,String>.from(saved);
    } catch (_) { localPasswords={}; }
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
    final password=TextEditingController(text:old==null?'':localPasswords[old.id]??'');
    var visible=false;
    String category=old?.category??categories[1];
    final result=await showDialog<bool>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,update)=>AlertDialog(
      title:Text(index==null?'サイトを分類に追加':'登録情報を編集'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('パスワードはこの端末のブラウザ内に平文保存されます。クラウド同期・バックアップ対象外です。',style:TextStyle(fontSize:12)),
        const SizedBox(height:12),
        TextField(controller:title,decoration:const InputDecoration(labelText:'サイト・サービス名')),
        DropdownButtonFormField<String>(initialValue:category,isExpanded:true,
          items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
          onChanged:(x)=>update(()=>category=x??category)),
        TextField(controller:note,decoration:const InputDecoration(labelText:'メモ')),
        TextField(controller:password,obscureText:!visible,decoration:InputDecoration(labelText:'パスワード（この端末のみ）',suffixIcon:IconButton(icon:Icon(visible?Icons.visibility_off:Icons.visibility),onPressed:()=>update(()=>visible=!visible)))),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('キャンセル')),
        FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('保存')),
      ],
    )));
    if(result==true&&title.text.trim().isNotEmpty){
      final state=AppStateScope.of(context);
      final id=old?.id??state.id();
      state.saveEntry('accountIndex',SimpleEntry(id:id,title:title.text.trim(),category:category,note:note.text.trim()));
      final p=await SharedPreferences.getInstance();
      if(password.text.isEmpty){localPasswords.remove(id);}else{localPasswords[id]=password.text;}
      await p.setString(passwordKey,jsonEncode(localPasswords));
      await _save();
    }
    title.dispose();note.dispose();password.dispose();
  }
  Future<void> _remove(int index)async{
    final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('一覧から削除しますか？'),
      content:const Text('Neru Memory内の分類情報だけを削除します。Googleに保存したパスワードは削除されません。'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('キャンセル')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('削除'))]));
    if(confirmed==true){
      final id=items[index].id;
      AppStateScope.of(context).removeEntry('accountIndex',items[index]);
      localPasswords.remove(id);
      final p=await SharedPreferences.getInstance();
      await p.setString(passwordKey,jsonEncode(localPasswords));
      await _save();
    }
  }
  @override Widget build(BuildContext context){
    final q=search.text.trim().toLowerCase();
    final shown=items.asMap().entries.where((e)=>(filter=='すべて'||e.value.category==filter)&&
      (q.isEmpty||[e.value.title,e.value.category,e.value.note].any((v)=>v.toLowerCase().contains(q)))).toList();
    return Scaffold(
      appBar:AppBar(title:const Text('パスワード管理'),actions:[
        IconButton(tooltip:'Googleで管理',icon:const Icon(Icons.open_in_new),onPressed:_openManager),
      ]),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('アカウントを追加')),
      body:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('パスワードを直接登録できます',style:TextStyle(fontWeight:FontWeight.bold)),
          const SizedBox(height:6),
          const Text('サイト名・分類・メモ・パスワードを登録できます。パスワードはこの端末内だけに保存され、他端末には同期されません。'),
          const SizedBox(height:8),
          FilledButton.icon(onPressed:_openManager,icon:const Icon(Icons.key),label:const Text('Google パスワード マネージャーを開く')),
          const SizedBox(height:6),
          const Text('注意：端末内のパスワードは暗号化されません。共有PCでの使用や重要アカウントの登録は推奨しません。',style:TextStyle(fontSize:12)),
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
          trailing:Row(mainAxisSize:MainAxisSize.min,children:[
            if(localPasswords.containsKey(entry.value.id))IconButton(tooltip:'パスワードをコピー',icon:const Icon(Icons.copy_outlined),onPressed:()async{
              await Clipboard.setData(ClipboardData(text:localPasswords[entry.value.id]!));
              if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('パスワードをコピーしました')));
            }),
            PopupMenuButton<String>(onSelected:(v){if(v=='delete')_remove(entry.key);else _edit(entry.key);},
              itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('編集')),PopupMenuItem(value:'delete',child:Text('削除'))]),
          ]),
        )),
      ]),
    );
  }
}
