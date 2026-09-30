package com.example.neru_memory

import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.widget.EditText
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity:FlutterActivity(){
  private val widgetChannelName="neru_memory/widgets"
  private val updateChannelName="neru_memory/app_update"
  private var widgetChannel:MethodChannel?=null

  override fun configureFlutterEngine(flutterEngine:FlutterEngine){
    super.configureFlutterEngine(flutterEngine)
    widgetChannel=MethodChannel(flutterEngine.dartExecutor.binaryMessenger,widgetChannelName)
    widgetChannel?.setMethodCallHandler{call,result->
      when(call.method){
        "updateToday"->{
          val args=call.arguments as? Map<*,*>?:emptyMap<Any,Any>()
          val items=args["items"] as? List<*>?:emptyList<Any>()
          val overdueCount=(args["overdueCount"] as? Number)?.toInt()?:0
          val todayCount=(args["todayCount"] as? Number)?.toInt()?:0
          getSharedPreferences("neru_widget",MODE_PRIVATE).edit().putString("today_items",items.filterIsInstance<String>().joinToString("\n")).putInt("overdue_count",overdueCount).putInt("today_count",todayCount).apply()
          updateTodayWidgets();result.success(null)
        }
        else->result.notImplemented()
      }
    }
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger,updateChannelName).setMethodCallHandler{call,result->
      when(call.method){
        "getBuildNumber"->{@Suppress("DEPRECATION") result.success(packageManager.getPackageInfo(packageName,0).versionCode)}
        "installApk"->{
          val path=call.argument<String>("path")
          if(path.isNullOrBlank())result.error("BAD_PATH","APK path is missing",null)
          else try{installApk(path);result.success(null)}catch(e:Exception){result.error("INSTALL_FAILED",e.message,null)}
        }
        else->result.notImplemented()
      }
    }
  }
  override fun onCreate(savedInstanceState:Bundle?){super.onCreate(savedInstanceState);maybeOpenQuickCapture(intent)}
  override fun onNewIntent(intent:Intent){super.onNewIntent(intent);setIntent(intent);maybeOpenQuickCapture(intent)}
  private fun maybeOpenQuickCapture(intent:Intent?){
    if(intent?.action!="com.example.neru_memory.QUICK_CAPTURE")return
    window.decorView.postDelayed({
      val input=EditText(this).apply{hint="未分類へメモ"}
      AlertDialog.Builder(this).setTitle("Quick Capture").setView(input).setNegativeButton("キャンセル",null).setPositiveButton("保存"){_,_->
        val text=input.text.toString().trim();if(text.isNotEmpty())widgetChannel?.invokeMethod("quickCapture",text)
      }.show()
    },350)
  }
  private fun installApk(path:String){
    if(!packageManager.canRequestPackageInstalls()){
      startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,Uri.parse("package:$packageName")))
      throw IllegalStateException("Neru Memoryの「不明なアプリのインストール」を許可してから、もう一度更新してください")
    }
    val uri=FileProvider.getUriForFile(this,"$packageName.fileprovider",File(path))
    startActivity(Intent(Intent.ACTION_VIEW).apply{setDataAndType(uri,"application/vnd.android.package-archive");addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)})
  }
  private fun updateTodayWidgets(){val manager=AppWidgetManager.getInstance(this);val component=ComponentName(this,TodayWidgetProvider::class.java);TodayWidgetProvider.updateAll(this,manager,manager.getAppWidgetIds(component))}
}
