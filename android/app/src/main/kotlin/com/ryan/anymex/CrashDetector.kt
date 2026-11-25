package com.ryan.anymex

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.os.Build
import android.util.Log
import java.io.File

object CrashDetector {
    private const val TAG = "CrashDetector"
    private const val PREFS_NAME = "anymex_crash_detector"
    private const val KEY_BRIDGE_LOADING = "bridge_loading"
    private const val KEY_BRIDGE_LOAD_TS = "bridge_load_ts"
    private const val KEY_BRIDGE_BLOCKED = "bridge_blocked"
    private const val KEY_LAST_EXIT_TS = "last_reported_exit_ts"
    private const val NATIVE_CRASH_FILE = "last_native_crash.txt"

    private var handlerInstalled = false

    fun installUncaughtExceptionHandler(context: Context) {
        if (handlerInstalled) return
        handlerInstalled = true
        val appContext = context.applicationContext
        val previousHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val bridgeLoading = prefs.getBoolean(KEY_BRIDGE_LOADING, false)
                val crashFile = File(appContext.filesDir, NATIVE_CRASH_FILE)
                val report = buildString {
                    appendLine("Timestamp: ${System.currentTimeMillis()}")
                    appendLine("Thread: ${thread.name} (id=${thread.id})")
                    appendLine("BridgeLoadingActive: $bridgeLoading")
                    appendLine("Exception: ${throwable.javaClass.name}: ${throwable.message}")
                    appendLine(Log.getStackTraceString(throwable))
                }
                crashFile.writeText(report)
            } catch (_: Throwable) {
            }
            previousHandler?.uncaughtException(thread, throwable)
        }
    }

    fun markBridgeLoadStart(context: Context) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_BRIDGE_LOADING, true)
            .putLong(KEY_BRIDGE_LOAD_TS, System.currentTimeMillis())
            .commit()
    }

    fun markBridgeLoadComplete(context: Context) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_BRIDGE_LOADING, false)
            .commit()
    }

    fun isBridgeBlocked(context: Context): Boolean {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_BRIDGE_BLOCKED, false)
    }

    fun setBridgeBlocked(context: Context, blocked: Boolean) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_BRIDGE_BLOCKED, blocked)
            .commit()
    }

    fun consumeCrashReport(context: Context): Map<String, Any?>? {
        val appContext = context.applicationContext
        val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val bridgeLoadingWasActive = prefs.getBoolean(KEY_BRIDGE_LOADING, false)
        val bridgeLoadTs = prefs.getLong(KEY_BRIDGE_LOAD_TS, 0L)
        if (bridgeLoadingWasActive) {
            prefs.edit()
                .putBoolean(KEY_BRIDGE_LOADING, false)
                .putBoolean(KEY_BRIDGE_BLOCKED, true)
                .commit()
        }

        var uncaughtCrashText: String? = null
        val crashFile = File(appContext.filesDir, NATIVE_CRASH_FILE)
        if (crashFile.exists()) {
            try {
                uncaughtCrashText = crashFile.readText()
                crashFile.delete()
            } catch (_: Throwable) {
            }
        }

        var exitReasonName: String? = null
        var exitDescription: String? = null
        var exitTimestamp: Long? = null
        var exitStatus: Int? = null
        var exitIsCrash = false
        var exitTrace: String? = null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val am = appContext.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                val reasons = am?.getHistoricalProcessExitReasons(appContext.packageName, 0, 5)
                val latest = reasons?.firstOrNull()
                if (latest != null) {
                    val lastReportedTs = prefs.getLong(KEY_LAST_EXIT_TS, 0L)
                    if (latest.timestamp > lastReportedTs) {
                        prefs.edit().putLong(KEY_LAST_EXIT_TS, latest.timestamp).commit()
                        exitReasonName = mapExitReason(latest.reason)
                        exitDescription = latest.description
                        exitTimestamp = latest.timestamp
                        exitStatus = latest.status
                        exitIsCrash = latest.reason == ApplicationExitInfo.REASON_CRASH ||
                            latest.reason == ApplicationExitInfo.REASON_CRASH_NATIVE ||
                            latest.reason == ApplicationExitInfo.REASON_ANR ||
                            latest.reason == ApplicationExitInfo.REASON_INITIALIZATION_FAILURE ||
                            latest.reason == ApplicationExitInfo.REASON_LOW_MEMORY
                        if (exitIsCrash) {
                            try {
                                latest.traceInputStream?.use { stream ->
                                    val bytes = ByteArray(4096)
                                    val read = stream.read(bytes)
                                    if (read > 0) {
                                        exitTrace = String(bytes, 0, read, Charsets.UTF_8)
                                    }
                                }
                            } catch (_: Throwable) {
                            }
                        }
                    }
                }
            } catch (t: Throwable) {
                Log.w(TAG, "Failed to read historical process exit reasons: ${t.message}")
            }
        }

        val hasCrash = bridgeLoadingWasActive || uncaughtCrashText != null || exitIsCrash
        if (!hasCrash) {
            return null
        }

        return mapOf(
            "bridgeLoadingWasActive" to bridgeLoadingWasActive,
            "bridgeBlocked" to prefs.getBoolean(KEY_BRIDGE_BLOCKED, false),
            "bridgeLoadTimestamp" to bridgeLoadTs,
            "uncaughtException" to uncaughtCrashText,
            "exitReason" to exitReasonName,
            "exitIsCrash" to exitIsCrash,
            "exitDescription" to exitDescription,
            "exitTimestamp" to exitTimestamp,
            "exitStatus" to exitStatus,
            "exitTrace" to exitTrace
        )
    }

    private fun mapExitReason(reason: Int): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return "UNKNOWN"
        return when (reason) {
            ApplicationExitInfo.REASON_ANR -> "REASON_ANR"
            ApplicationExitInfo.REASON_CRASH -> "REASON_CRASH"
            ApplicationExitInfo.REASON_CRASH_NATIVE -> "REASON_CRASH_NATIVE"
            ApplicationExitInfo.REASON_DEPENDENCY_DIED -> "REASON_DEPENDENCY_DIED"
            ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE -> "REASON_EXCESSIVE_RESOURCE_USAGE"
            ApplicationExitInfo.REASON_EXIT_SELF -> "REASON_EXIT_SELF"
            ApplicationExitInfo.REASON_INITIALIZATION_FAILURE -> "REASON_INITIALIZATION_FAILURE"
            ApplicationExitInfo.REASON_LOW_MEMORY -> "REASON_LOW_MEMORY"
            ApplicationExitInfo.REASON_OTHER -> "REASON_OTHER"
            ApplicationExitInfo.REASON_PERMISSION_CHANGE -> "REASON_PERMISSION_CHANGE"
            ApplicationExitInfo.REASON_SIGNALED -> "REASON_SIGNALED"
            ApplicationExitInfo.REASON_USER_REQUESTED -> "REASON_USER_REQUESTED"
            ApplicationExitInfo.REASON_USER_STOPPED -> "REASON_USER_STOPPED"
            else -> "UNKNOWN($reason)"
        }
    }
}
