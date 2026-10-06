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

            val body =
                if (raw.isBlank()) "今日のTaskはありません" else raw

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
                views.setTextViewText(R.id.widget_items, body)

                val firstTaskId = taskIds.firstOrNull()
                if (firstTaskId != null) {
                    val complete = Intent(context, MainActivity::class.java).apply {
                        action = "com.example.neru_memory.COMPLETE_TASK"
                        putExtra("taskId", firstTaskId)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                    val completePi = PendingIntent.getActivity(
                        context, 203, complete,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_complete, completePi)
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
