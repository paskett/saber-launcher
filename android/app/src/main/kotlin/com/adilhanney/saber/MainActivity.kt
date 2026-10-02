package com.adilhanney.saber

import android.content.Intent
import android.os.Bundle
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK

class MainActivity: FlutterActivity() {
    private val launcherChannel = "com.adilhanney.saber/launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, launcherChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listApps" -> {
                        try {
                            val intent = Intent(Intent.ACTION_MAIN)
                                .addCategory(Intent.CATEGORY_LAUNCHER)
                            val apps = packageManager.queryIntentActivities(intent, 0)
                                .map { resolveInfo ->
                                    mapOf(
                                        "label" to resolveInfo.loadLabel(packageManager).toString(),
                                        "packageName" to resolveInfo.activityInfo.packageName,
                                    )
                                }
                                .filter { it["packageName"] != "com.adilhanney.saber" }
                                .distinctBy { it["packageName"] }
                                .sortedBy { it["label"]!!.lowercase() }
                            result.success(apps)
                        } catch (e: Exception) {
                            result.error("LIST_APPS_FAILED", e.message, null)
                        }
                    }
                    "launchApp" -> {
                        try {
                            val packageName = call.argument<String>("packageName")
                            val launchIntent = packageName?.let {
                                packageManager.getLaunchIntentForPackage(it)
                            }
                            if (launchIntent != null) {
                                launchIntent.addFlags(FLAG_ACTIVITY_NEW_TASK)
                                startActivity(launchIntent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("LAUNCH_APP_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
            this.finish()
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)

        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightNavigationBars = true
    }
}
