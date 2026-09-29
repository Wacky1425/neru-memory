package com.example.neru_memory

import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.widget.EditText
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "neru_memory/widgets"
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateToday" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    val items = args["items"] as? List<*> ?: emptyList<Any>()
                    val overdueCount = (args["overdueCount"] as? Number)?.toInt() ?: 0
                    val todayCount = (args["todayCount"] as? Number)?.toInt() ?: 0
                    val prefs = getSharedPreferences("neru_widget", MODE_PRIVATE)
                    prefs.edit()
                        .putString("today_items", items.filterIsInstance<String>().joinToString("\n"))
                        .putInt("overdue_count", overdueCount)
                        .putInt("today_count", todayCount)
                        .apply()
                    updateTodayWidgets()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        maybeOpenQuickCapture(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        maybeOpenQuickCapture(intent)
    }

    private fun maybeOpenQuickCapture(intent: Intent?) {
        if (intent?.action != "com.example.neru_memory.QUICK_CAPTURE") return
        window.decorView.postDelayed({
            val input = EditText(this).apply { hint = "未分類へメモ" }
            AlertDialog.Builder(this)
                .setTitle("Quick Capture")
                .setView(input)
                .setNegativeButton("キャンセル", null)
                .setPositiveButton("保存") { _, _ ->
                    val text = input.text.toString().trim()
                    if (text.isNotEmpty()) channel?.invokeMethod("quickCapture", text)
                }.show()
        }, 350)
    }

    private fun updateTodayWidgets() {
        val manager = AppWidgetManager.getInstance(this)
        val component = ComponentName(this, TodayWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        TodayWidgetProvider.updateAll(this, manager, ids)
    }
}
