import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';

/// Converts a VOD timestamp to a link. Does not alter unrelated URL parameters.
class ClipLinks {
  static int? seconds(String raw) {
    final parts=raw.trim().split(':');
    if(parts.isEmpty||parts.length>3)return null;
    var total=0;
    for(final part in parts){
      final n=int.tryParse(part);
      if(n==null||n<0||n>59&&parts.indexOf(part)!=0)return null;
      total=total*60+n;
    }
    return total;
  }
  static Uri? at(String url,String timestamp){
    final sec=seconds(timestamp);
    final uri=Uri.tryParse(url.trim());
    if(sec==null||uri==null||!uri.hasScheme||!['https','http'].contains(uri.scheme))return null;
    final host=uri.host.toLowerCase();
    if(host=='youtu.be'||host=='youtube.com'||host.endsWith('.youtube.com')){
      final params=Map<String,String>.from(uri.queryParameters)..remove('t')..remove('start');
      params['t']='${sec}s';
      return uri.replace(queryParameters:params,fragment:'');
    }
    if(host=='twitch.tv'||host.endsWith('.twitch.tv')){
      final params=Map<String,String>.from(uri.queryParameters);
      final h=sec~/3600,m=(sec%3600)~/60,s=sec%60;
      params['t']='${h}h${m}m${s}s';
      return uri.replace(queryParameters:params,fragment:'');
    }
    return null;
  }
}

class ShortsPage extends StatefulWidget {
  const ShortsPage({super.key});
  @override State<ShortsPage> createState()=>_ShortsPageState();
}
class _ShortsPageState extends State<ShortsPage>{
  String query='',filter='すべて';
  static const statuses=['候補','素材確保','編集中','完成','投稿済'];
  Future<void> edit(AppState state,[ShortClip? original])async{
    final title=TextEditingController(text:original?.title??'');
    final url=TextEditingController(text:original?.url??'');
    final note=TextEditingController(text:original?.note??'');
    final game=TextEditingController(text:original?.game??'');
    final segments=TextEditingController(text:(original?.segments??[]).join('\n'));
    var status=original?.status??statuses.first;
    var priority=original?.priority??'中';
    final ok=await showDialog<bool>(context:context,builder:(dialog)=>StatefulBuilder(builder:(c,update)=>AlertDialog(
      title:Text(original==null?'切り抜き候補を追加':'候補を編集'),
      content:SizedBox(width:480,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,autofocus:true,decoration:const InputDecoration(labelText:'どんな場面？（一覧の見出し）')),
        TextField(controller:url,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'配信URL（YouTube / Twitch）')),
        TextField(controller:segments,minLines:2,maxLines:5,decoration:const InputDecoration(labelText:'切り抜き時間（1行に1区間）',hintText:'01:23:40 - 01:24:35\n02:10:15 - 02:11:05',helperText:'開始時間をタップすると、その場面を開けます')),
        TextField(controller:game,decoration:const InputDecoration(labelText:'ゲーム・タグ（例：VALORANT）')),
        TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'編集メモ')),
        DropdownButtonFormField<String>(initialValue:status,decoration:const InputDecoration(labelText:'制作状況'),items:[for(final s in statuses)DropdownMenuItem(value:s,child:Text(s))],onChanged:(v)=>update(()=>status=v??status)),
        DropdownButtonFormField<String>(initialValue:priority,decoration:const InputDecoration(labelText:'優先度'),items:[for(final s in ['高','中','低'])DropdownMenuItem(value:s,child:Text(s))],onChanged:(v)=>update(()=>priority=v??priority)),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('キャンセル')),FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:const Text('保存'))],
    )));
    if(ok==true&&title.text.trim().isNotEmpty){
      final times=segments.text.split('\n').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList();
      state.saveShortClip(ShortClip(id:original?.id??state.id(),title:title.text.trim(),url:url.text.trim(),segments:times,note:note.text.trim(),game:game.text.trim(),status:status,priority:priority));
    }
    title.dispose();url.dispose();note.dispose();game.dispose();segments.dispose();
  }
  Future<void> openAt(String url,String timestamp)async{
    final link=ClipLinks.at(url,timestamp);
    if(link==null){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('YouTube・Twitchの配信URLと開始時間を確認してください')));
      return;
    }
    if(!await launchUrl(link,mode:LaunchMode.externalApplication)&&mounted){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('動画を開けませんでした')));
    }
  }
  String startOf(String segment){
    final match=RegExp(r'^\s*(\d{1,3}:)?\d{1,2}:\d{2}|^\s*\d+').firstMatch(segment);
    return match?.group(0)?.trim()??segment;
  }
  @override Widget build(BuildContext context){
    final state=AppStateScope.of(context);
    final clips=state.shortClips.where((x)=>(filter=='すべて'||x.status==filter)&&
      (query.isEmpty||'${x.title} ${x.game} ${x.note}'.toLowerCase().contains(query.toLowerCase()))).toList()
      ..sort((a,b)=>b.updatedAt.compareTo(a.updatedAt));
    return Scaffold(
      appBar:AppBar(title:const Text('Shorts制作')),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(state),icon:const Icon(Icons.add),label:const Text('候補を追加')),
      body:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[
        TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'場面・ゲーム・メモで検索',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>query=v)),
        const SizedBox(height:12),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
          for(final s in ['すべて',...statuses])Padding(padding:const EdgeInsets.only(right:6),child:ChoiceChip(label:Text(s),selected:filter==s,onSelected:(_)=>setState(()=>filter=s))),
        ])),
        if(clips.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('切り抜き候補を登録するとここに表示されます')),
        for(final clip in clips)Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Expanded(child:Text(clip.title,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold))),
            PopupMenuButton<String>(onSelected:(v)async{
              if(v=='edit'){edit(state,clip);return;}
              final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('候補を削除しますか？'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('キャンセル')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('削除'))]));
              if(yes==true)state.removeShortClip(clip);
            },itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('編集')),PopupMenuItem(value:'delete',child:Text('削除'))]),
          ]),
          Wrap(spacing:8,children:[Chip(label:Text(clip.status)),if(clip.game.isNotEmpty)Chip(label:Text(clip.game)),Chip(label:Text('優先度 ${clip.priority}'))]),
          for(final segment in clip.segments)Padding(padding:const EdgeInsets.symmetric(vertical:3),child:TextButton.icon(
            onPressed:()=>openAt(clip.url,startOf(segment)),icon:const Icon(Icons.play_circle_outline),label:Text(segment),
          )),
          if(clip.note.isNotEmpty)Padding(padding:const EdgeInsets.only(top:6),child:Text(clip.note,maxLines:3,overflow:TextOverflow.ellipsis)),
          if(clip.url.isNotEmpty)TextButton.icon(onPressed:()=>openAt(clip.url,'0:00'),icon:const Icon(Icons.open_in_new),label:const Text('配信元を開く')),
        ]))),
      ]),
    );
  }
}
