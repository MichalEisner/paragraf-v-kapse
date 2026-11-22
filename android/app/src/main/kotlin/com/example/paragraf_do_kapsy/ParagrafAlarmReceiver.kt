package com.example.paragraf_do_kapsy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class ParagrafAlarmReceiver : BroadcastReceiver() {
    private val TAG = "ParagrafAlarmReceiver"

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return

        val action = intent.action
        Log.d(TAG, "onReceive invoked with action: $action")

        if (Intent.ACTION_BOOT_COMPLETED == action ||
            Intent.ACTION_MY_PACKAGE_REPLACED == action ||
            "android.intent.action.QUICKBOOT_POWERON" == action) {
            // Phone rebooted - restore all pending scheduled alarms
            Log.d(TAG, "Device rebooted. Rescheduling all pending offline reminders...")
            NotificationHelper.rescheduleAllAlarms(context)
            return
        }

        // Alarm trigger received while app is closed, backgrounded or foregrounded
        val id = intent.getIntExtra("id", (System.currentTimeMillis() % 100000).toInt())
        val title = intent.getStringExtra("title") ?: "Paragraf v kapse"
        val body = intent.getStringExtra("body") ?: "Upozornění z aplikace Paragraf v kapse"
        val contractId = intent.getStringExtra("contract_id")

        Log.d(TAG, "Executing alarm notification: id=$id, title=$title, closedAppMode=true")

        // Display the native notification
        NotificationHelper.showNotification(
            context = context,
            notificationId = id,
            title = title,
            body = body,
            contractId = contractId
        )

        // Remove from persistent storage since it has already fired
        NotificationHelper.removeAlarm(context, id)
    }
}
