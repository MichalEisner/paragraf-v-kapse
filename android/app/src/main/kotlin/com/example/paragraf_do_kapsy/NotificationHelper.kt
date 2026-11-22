package com.example.paragraf_do_kapsy

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject

data class ScheduledAlarmInfo(
    val id: Int,
    val triggerTimeMillis: Long,
    val title: String,
    val body: String,
    val contractId: String?
)

object NotificationHelper {
    private const val TAG = "NotificationHelper"
    private const val PREFS_NAME = "paragraf_alarms_prefs"
    const val CHANNEL_ID = "paragraf_alerts"
    const val ACTION_ALARM_TRIGGER = "com.example.paragraf_do_kapsy.ALARM_TRIGGER"

    fun ensureNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Upozornění Paragraf v kapse",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Upozornění na konec smluv a zkušební doby i při vypnuté aplikaci"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
                setSound(soundUri, null)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showNotification(
        context: Context,
        notificationId: Int,
        title: String,
        body: String,
        contractId: String? = null
    ) {
        ensureNotificationChannel(context)
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val notifIconRes = try {
            val resId = context.resources.getIdentifier("ic_notification", "drawable", context.packageName)
            if (resId != 0) resId else android.R.drawable.ic_dialog_info
        } catch (_: Exception) {
            android.R.drawable.ic_dialog_info
        }

        val largeIconBitmap = try {
            val resId = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName)
            if (resId != 0) BitmapFactory.decodeResource(context.resources, resId) else null
        } catch (_: Exception) {
            null
        }

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (contractId != null) {
                putExtra("contract_id", contractId)
            }
        }

        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, notificationId, launchIntent, pendingFlags)

        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(notifIconRes)
            .apply {
                if (largeIconBitmap != null) {
                    setLargeIcon(largeIconBitmap)
                }
            }
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setSound(defaultSoundUri)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        notificationManager.notify(notificationId, builder.build())
        Log.d(TAG, "Notification $notificationId displayed successfully: $title")
    }

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun saveAlarm(
        context: Context,
        id: Int,
        triggerTimeMillis: Long,
        title: String,
        body: String,
        contractId: String? = null
    ) {
        val json = JSONObject().apply {
            put("id", id)
            put("triggerTimeMillis", triggerTimeMillis)
            put("title", title)
            put("body", body)
            if (contractId != null) {
                put("contractId", contractId)
            }
        }
        getPrefs(context).edit().putString("alarm_$id", json.toString()).apply()
    }

    fun removeAlarm(context: Context, id: Int) {
        getPrefs(context).edit().remove("alarm_$id").apply()
    }

    fun getAllSavedAlarms(context: Context): List<ScheduledAlarmInfo> {
        val prefs = getPrefs(context)
        val list = mutableListOf<ScheduledAlarmInfo>()
        for ((key, value) in prefs.all) {
            if (key.startsWith("alarm_") && value is String) {
                try {
                    val obj = JSONObject(value)
                    list.add(
                        ScheduledAlarmInfo(
                            id = obj.getInt("id"),
                            triggerTimeMillis = obj.getLong("triggerTimeMillis"),
                            title = obj.getString("title"),
                            body = obj.getString("body"),
                            contractId = if (obj.has("contractId")) obj.getString("contractId") else null
                        )
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "Failed parsing saved alarm $key", e)
                }
            }
        }
        return list
    }

    fun scheduleAlarm(
        context: Context,
        id: Int,
        triggerTimeMillis: Long,
        title: String,
        body: String,
        contractId: String? = null
    ) {
        saveAlarm(context, id, triggerTimeMillis, title, body, contractId)

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ParagrafAlarmReceiver::class.java).apply {
            action = ACTION_ALARM_TRIGGER
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)
            if (contractId != null) {
                putExtra("contract_id", contractId)
            }
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(context, id, intent, flags)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTimeMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTimeMillis,
                        pendingIntent
                    )
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTimeMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerTimeMillis,
                    pendingIntent
                )
            }
            Log.d(TAG, "Scheduled alarm $id for $triggerTimeMillis (closed app supported)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule alarm with AlarmManager", e)
            // Fallback to inexact idle-allowed
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTimeMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
                }
            } catch (e2: Exception) {
                Log.e(TAG, "Fallback schedule also failed", e2)
            }
        }
    }

    fun cancelAlarm(context: Context, id: Int) {
        removeAlarm(context, id)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ParagrafAlarmReceiver::class.java).apply {
            action = ACTION_ALARM_TRIGGER
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(context, id, intent, flags)
        try {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        } catch (_: Exception) {}
        Log.d(TAG, "Cancelled alarm $id")
    }

    fun cancelAllAlarms(context: Context) {
        val alarms = getAllSavedAlarms(context)
        for (a in alarms) {
            cancelAlarm(context, a.id)
        }
        getPrefs(context).edit().clear().apply()
        Log.d(TAG, "Cancelled all alarms (${alarms.size})")
    }

    fun rescheduleAllAlarms(context: Context) {
        val alarms = getAllSavedAlarms(context)
        val now = System.currentTimeMillis()
        var rescheduledCount = 0
        for (alarm in alarms) {
            if (alarm.triggerTimeMillis > now) {
                // Re-register active future alarm
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val intent = Intent(context, ParagrafAlarmReceiver::class.java).apply {
                    action = ACTION_ALARM_TRIGGER
                    putExtra("id", alarm.id)
                    putExtra("title", alarm.title)
                    putExtra("body", alarm.body)
                    if (alarm.contractId != null) {
                        putExtra("contract_id", alarm.contractId)
                    }
                }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getBroadcast(context, alarm.id, intent, flags)

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        if (alarmManager.canScheduleExactAlarms()) {
                            alarmManager.setExactAndAllowWhileIdle(
                                AlarmManager.RTC_WAKEUP,
                                alarm.triggerTimeMillis,
                                pendingIntent
                            )
                        } else {
                            alarmManager.setAndAllowWhileIdle(
                                AlarmManager.RTC_WAKEUP,
                                alarm.triggerTimeMillis,
                                pendingIntent
                            )
                        }
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            alarm.triggerTimeMillis,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setExact(
                            AlarmManager.RTC_WAKEUP,
                            alarm.triggerTimeMillis,
                            pendingIntent
                        )
                    }
                    rescheduledCount++
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to reschedule alarm ${alarm.id} after boot", e)
                }
            } else {
                // Clean up expired alarm
                removeAlarm(context, alarm.id)
            }
        }
        Log.d(TAG, "Rescheduled $rescheduledCount alarms after device boot")
    }
}
