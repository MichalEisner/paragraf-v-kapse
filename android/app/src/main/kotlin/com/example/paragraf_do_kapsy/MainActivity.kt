package com.example.paragraf_do_kapsy

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "paragraf/native"
    private val PICK_FILE_REQUEST_CODE = 4281
    private val NOTIF_PERMISSION_REQUEST_CODE = 4282
    private var pendingFileResult: MethodChannel.Result? = null
    private var pendingNotifResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "areNotificationsEnabled" -> {
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    val enabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED && nm.areNotificationsEnabled()
                    } else {
                        nm.areNotificationsEnabled()
                    }
                    result.success(enabled)
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            pendingNotifResult = result
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIF_PERMISSION_REQUEST_CODE)
                            return@setMethodCallHandler
                        }
                    }
                    result.success(true)
                }
                "openNotificationSettings" -> {
                    try {
                        val intent = Intent().apply {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            } else {
                                action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                                data = Uri.fromParts("package", packageName, null)
                            }
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Paragraf v kapse"
                    val body = call.argument<String>("body") ?: ""
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                                pendingNotifResult = result
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIF_PERMISSION_REQUEST_CODE)
                                return@setMethodCallHandler
                            }
                        }
                        showSystemNotification(title, body)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", e.message, null)
                    }
                }
                "isOnline" -> {
                    try {
                        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
                        val isConnected = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val network = cm.activeNetwork
                            val caps = cm.getNetworkCapabilities(network)
                            caps != null && (caps.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_INTERNET))
                        } else {
                            @Suppress("DEPRECATION")
                            cm.activeNetworkInfo?.isConnectedOrConnecting == true
                        }
                        result.success(isConnected)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "pickBackupFile" -> {
                    pendingFileResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                    }
                    try {
                        startActivityForResult(intent, PICK_FILE_REQUEST_CODE)
                    } catch (e: Exception) {
                        try {
                            val fallbackIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                                type = "*/*"
                            }
                            startActivityForResult(fallbackIntent, PICK_FILE_REQUEST_CODE)
                        } catch (e2: Exception) {
                            pendingFileResult = null
                            result.error("PICK_FAILED", e2.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showSystemNotification(title: String, body: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "paragraf_alerts"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val channel = NotificationChannel(
                channelId,
                "Upozornění Paragraf v kapse",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Upozornění na konec smluv a zkušební doby"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
                setSound(soundUri, null)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val notifIconRes = try {
            val resId = resources.getIdentifier("ic_notification", "drawable", packageName)
            if (resId != 0) resId else android.R.drawable.ic_dialog_info
        } catch (_: Exception) {
            android.R.drawable.ic_dialog_info
        }

        val largeIconBitmap = try {
            val resId = resources.getIdentifier("ic_launcher", "mipmap", packageName)
            if (resId != 0) BitmapFactory.decodeResource(resources, resId) else null
        } catch (_: Exception) {
            null
        }

        val notificationId = (System.currentTimeMillis() % 100000).toInt()
        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val builder = NotificationCompat.Builder(this, channelId)
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

        notificationManager.notify(notificationId, builder.build())
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIF_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (granted) {
                showSystemNotification("Paragraf v kapse", "Upozornění byla úspěšně povolena pro váš telefon.")
            }
            pendingNotifResult?.success(granted)
            pendingNotifResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_FILE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                try {
                    val uri: Uri = data.data!!
                    contentResolver.openInputStream(uri)?.use { inputStream ->
                        val reader = BufferedReader(InputStreamReader(inputStream))
                        val content = reader.readText()
                        pendingFileResult?.success(content)
                    } ?: run {
                        pendingFileResult?.error("FILE_READ_ERROR", "Nepodařilo se otevřít soubor.", null)
                    }
                } catch (e: Exception) {
                    pendingFileResult?.error("FILE_READ_ERROR", e.message, null)
                }
            } else {
                pendingFileResult?.success(null)
            }
            pendingFileResult = null
        }
    }
}
