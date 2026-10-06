package com.example.neru_memory

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class TodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        updateAll(context, manager, ids)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, TodayWidgetProvider::class.java)
            )
            updateAll(context, manager, ids)
        }
    }

    companion object {
        private const val ACTION_REFRESH =
            "com.example.neru_memory.REFRESH_WIDGET"

        fun updateAll(
            context: Context,
            manager: AppWidgetManager,
            ids: IntArray
        ) {
            val prefs = context.getSharedPreferences(
                "neru_widget",
                Context.MODE_PRIVATE
            )
            val raw = prefs.getString("today_items", "").orEmpty()
            val taskIds = prefs.getString("today_task_ids", "").orEmpty()
                .split("\n").filter { it.isNotBlank() }
            val overdue = prefs.getInt("overdue_count", 0)
            val today = prefs.getInt("today_count", 0)

            val taskLines = raw.split("\n").filter { it.isNotBlank() }

            // ${overdue}件 のように境界を明示し、日本語が変数名として
            // 解釈されないようにする。
            val summary =
                if (overdue > 0) {
                    "期限切れ ${overdue}件  /  今日 ${today}件"
                } else {
                    "今日 ${today}件"
                }

            ids.forEach { id ->
                val views = RemoteViews(
                    context.packageName,
                    R.layout.widget_today
                )
                views.setTextViewText(R.id.widget_summary, summary)

                val rowIds = intArrayOf(
                    R.id.widget_task_0, R.id.widget_task_1, R.id.widget_task_2,
                    R.id.widget_task_3, R.id.widget_task_4, R.id.widget_task_5
                )
                rowIds.forEachIndexed { index, rowId ->
                    val title = taskLines.getOrNull(index)
                    val taskId = taskIds.getOrNull(index)
                    if (title != null && taskId != null) {
                        views.setViewVisibility(rowId, android.view.View.VISIBLE)
                        views.setTextViewText(rowId, "☐ $title")
                        val complete = Intent(context, MainActivity::class.java).apply {
                            action = "com.example.neru_memory.COMPLETE_TASK"
                            putExtra("taskId", taskId)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        val completePi = PendingIntent.getActivity(
                            context, 300 + index, complete,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(rowId, completePi)
                    } else {
                        views.setViewVisibility(rowId, android.view.View.GONE)
                    }
                }
                if (taskLines.isEmpty()) {
                    views.setViewVisibility(R.id.widget_task_0, android.view.View.VISIBLE)
                    views.setTextViewText(R.id.widget_task_0, "今日のTaskはありません")
                }

                val open = Intent(context, MainActivity::class.java)
                val openPi = PendingIntent.getActivity(
                    context,
                    0,
                    open,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    openPi
                )

                val capture =
                    Intent(context, MainActivity::class.java).apply {
                        action =
                            "com.example.neru_memory.QUICK_CAPTURE"
                        flags =
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                val capturePi = PendingIntent.getActivity(
                    context,
                    201,
                    capture,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(
                    R.id.widget_add,
                    capturePi
                )

                val refresh =
                    Intent(
                        context,
                        TodayWidgetProvider::class.java
                    ).apply {
                        action = ACTION_REFRESH
                    }
                val refreshPi = PendingIntent.getBroadcast(
                    context,
                    202,
                    refresh,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(
                    R.id.widget_refresh,
                    refreshPi
                )

                manager.updateAppWidget(id, views)
            }
        }
    }
}
