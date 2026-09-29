package com.example.neru_memory

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class QuickCaptureWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { id ->
            val views=RemoteViews(context.packageName,R.layout.widget_quick_capture)
            val intent=Intent(context,MainActivity::class.java).apply {
                action="com.example.neru_memory.QUICK_CAPTURE"
                flags=Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pi=PendingIntent.getActivity(context,100,intent,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.quick_capture_button,pi)
            manager.updateAppWidget(id,views)
        }
    }
}
