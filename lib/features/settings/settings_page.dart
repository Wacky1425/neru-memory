import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_state.dart';
import '../../core/app_update_service.dart';
import '../../core/google_calendar_service.dart';
import '../../widgets/common.dart';
import 'trash_page.dart';
import 'data_summary_page.dart';

class SettingsPage extends StatelessWidget{
  const SettingsPage({super.key});
  @override Widget build(BuildContext c){
    final s=AppStateScope.of(c);
    return Scaffold(appBar:AppBar(title:const Text('設定',style:TextStyle(fontWeight:FontWeight.w800))),body:PageWrap(child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
      const SectionTitle('表示'),Card(child:Column(children:[
        RadioListTile<ThemeMode>(value:ThemeMode.light,groupValue:s.themeMode,onChanged:(v){if(v!=null)s.setTheme(v);},title:const Text('ライト')),
        RadioListTile<ThemeMode>(value:ThemeMode.dark,groupValue:s.themeMode,onChanged:(v){if(v!=null)s.setTheme(v);},title:const Text('ダーク')),
        RadioListTile<ThemeMode>(value:ThemeMode.system,groupValue:s.themeMode,onChanged:(v){if(v!=null)s.setTheme(v);},title:const Text('端末設定'))])),
      const SectionTitle('連携'),Card(child:ListTile(leading:const Icon(Icons.calendar_month),title:const Text('Google Calendar'),subtitle:Text(GoogleCalendarService.instance.isConnected?'接続済み':'予定タブから接続'))),
      if(!kIsWeb)...[const SectionTitle('アプリ'),const Card(child:_UpdateTile())],
      const SectionTitle('思い出す'),const Card(child:ListTile(leading:Icon(Icons.lightbulb_outline),title:Text('REMEMBER'),subtitle:Text('7日以上見返していないWant・日時未定Future・Goalを優先して表示。あとで=7日、しばらく出さない=30日。'))),
      const SectionTitle('データ'),Card(child:Column(children:[
        ListTile(leading:const Icon(Icons.analytics_outlined),title:const Text('データ概要'),subtitle:const Text('保存している項目数を確認'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const DataSummaryPage()))),
        ListTile(leading:const Icon(Icons.delete_outline),title:const Text('ゴミ箱'),subtitle:Text('${s.trash.length}件 · 30日後に自動削除'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const TrashPage()))),
        ListTile(leading:const Icon(Icons.data_object),title:const Text('JSONエクスポート'),subtitle:const Text('バックアップ用JSONをコピー'),onTap:()async{await Clipboard.setData(ClipboardData(text:s.exportJson()));if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('JSONをコピーしました')));}),
        ListTile(leading:const Icon(Icons.cloud_done_outlined),title:const Text('Firestore同期'),subtitle:Text(s.cloudReady?'接続済み':s.cloudError??'Googleログイン後に同期'))])),
      const SizedBox(height:20),const Center(child:Text('Neru Memory v1.12'))
    ])));
  }
}

class _UpdateTile extends StatefulWidget{const _UpdateTile();@override State<_UpdateTile> createState()=>_UpdateTileState();}
class _UpdateTileState extends State<_UpdateTile>{
  bool checking=false,downloading=false;double? progress;
  Future<void> check()async{
    if(checking||downloading)return;setState(()=>checking=true);
    try{
      final info=await AppUpdateService.instance.check();if(!mounted)return;
      if(info==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('最新版です')));return;}
      final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('アップデートがあります'),content:Text('Neru Memory ${info.version} をインストールしますか？'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('あとで')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('更新する'))]));
      if(ok==true)await install(info);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('更新確認に失敗しました: $e')));}
    finally{if(mounted)setState(()=>checking=false);}
  }
  Future<void> install(AppUpdateInfo info)async{
    setState((){downloading=true;progress=null;});
    try{await AppUpdateService.instance.downloadAndInstall(info,onProgress:(r,t){if(mounted)setState(()=>progress=t>0?r/t:null);});}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('アップデートに失敗しました: $e')));}
    finally{if(mounted)setState((){downloading=false;progress=null;});}
  }
  @override Widget build(BuildContext context){
    final sub=downloading?(progress==null?'APKをダウンロード中…':'APKをダウンロード中… ${(progress!*100).round()}%'):'最新版を確認して、そのまま更新';
    return ListTile(leading:checking||downloading?const SizedBox(width:24,height:24,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.system_update_alt),title:const Text('アップデートを確認'),subtitle:Text(sub),trailing:const Icon(Icons.chevron_right),onTap:check);
  }
}
