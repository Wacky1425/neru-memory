import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AppUpdateInfo {
  const AppUpdateInfo({required this.buildNumber,required this.version,required this.downloadUrl});
  final int buildNumber;
  final String version;
  final String downloadUrl;
}

class AppUpdateService {
  AppUpdateService._();
  static final instance=AppUpdateService._();
  static const _channel=MethodChannel('neru_memory/app_update');
  static const _metadataUrl='https://raw.githubusercontent.com/Wacky1425/neru-memory/main/update.json';

  Future<AppUpdateInfo?> check() async {
    if(kIsWeb||!Platform.isAndroid)return null;
    final response=await http.get(Uri.parse(_metadataUrl)).timeout(const Duration(seconds:10));
    if(response.statusCode!=200)throw Exception('更新情報を取得できませんでした');
    final json=jsonDecode(utf8.decode(response.bodyBytes)) as Map<String,dynamic>;
    final latest=(json['buildNumber'] as num?)?.toInt()??0;
    final current=await _channel.invokeMethod<int>('getBuildNumber')??0;
    if(latest<=current)return null;
    return AppUpdateInfo(buildNumber:latest,version:json['version']?.toString()??'',downloadUrl:json['downloadUrl']?.toString()??'');
  }

  Future<void> downloadAndInstall(AppUpdateInfo info,{void Function(int,int)? onProgress}) async {
    final request=http.Request('GET',Uri.parse(info.downloadUrl));
    final response=await request.send().timeout(const Duration(seconds:20));
    if(response.statusCode!=200)throw Exception('APKを取得できませんでした');
    final dir=await getTemporaryDirectory();
    final file=File('${dir.path}/neru-memory-${info.buildNumber}.apk');
    final sink=file.openWrite();
    var received=0; final total=response.contentLength??0;
    try{
      await for(final chunk in response.stream){sink.add(chunk);received+=chunk.length;onProgress?.call(received,total);}
    }finally{await sink.close();}
    await _channel.invokeMethod<void>('installApk',{'path':file.path});
  }
}
