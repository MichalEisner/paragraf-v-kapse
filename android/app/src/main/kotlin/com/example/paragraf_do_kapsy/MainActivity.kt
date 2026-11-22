package com.example.paragraf_do_kapsy

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
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

        // Ensure notification channel exists on app startup
        NotificationHelper.ensureNotificationChannel(this)

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
                        val notifId = (System.currentTimeMillis() % 100000).toInt()
                        NotificationHelper.showNotification(this, notifId, title, body)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", e.message, null)
                    }
                }
                "scheduleAlarm" -> {
                    val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                    val triggerTimeMillis = (call.argument<Number>("triggerTimeMillis"))?.toLong() ?: 0L
                    val title = call.argument<String>("title") ?: "Paragraf v kapse"
                    val body = call.argument<String>("body") ?: ""
                    val contractId = call.argument<String>("contractId")

                    try {
                        NotificationHelper.scheduleAlarm(this, id, triggerTimeMillis, title, body, contractId)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCHEDULE_ERROR", e.message, null)
                    }
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("id")
                    if (id == null) {
                        result.error("ARG_ERROR", "id parameter is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        NotificationHelper.cancelAlarm(this, id)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_ERROR", e.message, null)
                    }
                }
                "cancelAllAlarms" -> {
                    try {
                        NotificationHelper.cancelAllAlarms(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_ALL_ERROR", e.message, null)
                    }
                }
                "getScheduledAlarms" -> {
                    try {
                        val alarms = NotificationHelper.getAllSavedAlarms(this)
                        val list = alarms.map {
                            mapOf(
                                "id" to it.id,
                                "triggerTimeMillis" to it.triggerTimeMillis,
                                "title" to it.title,
                                "body" to it.body,
                                "contractId" to it.contractId
                            )
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("GET_ALARMS_ERROR", e.message, null)
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

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIF_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (granted) {
                NotificationHelper.showNotification(
                    this,
                    999,
                    "Paragraf v kapse",
                    "Upozornění byla úspěšně povolena pro váš telefon."
                )
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
                    val uri = data.data!!
                    val inputStream = contentResolver.openInputStream(uri)
                    val reader = BufferedReader(InputStreamReader(inputStream))
                    val stringBuilder = StringBuilder()
                    var line: String? = reader.readLine()
                    while (line != null) {
                        stringBuilder.append(line).append('\n')
                        line = reader.readLine()
                    }
                    reader.close()
                    inputStream?.close()
                    pendingFileResult?.success(stringBuilder.toString())
                } catch (e: Exception) {
                    pendingFileResult?.error("READ_ERROR", "Chyba při čtení souboru: ${e.message}", null)
                }
            } else {
                pendingFileResult?.success(null)
            }
            pendingFileResult = null
        }
    }
}
