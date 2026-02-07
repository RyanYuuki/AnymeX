package com.ryan.anymex

import android.view.KeyEvent
import android.view.KeyEvent.ACTION_DOWN
import android.view.KeyEvent.KEYCODE_VOLUME_DOWN
import android.view.KeyEvent.KEYCODE_VOLUME_UP
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app/architecture"
    private val VOLUME_CHANNEL = "com.ryan.anymex/volume"
    private val VOLUME_EVENTS = "com.ryan.anymex/volume_events"
    private var volumeKeysEnabled = false
    private var volumeEventsSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentArchitecture" -> {
                    val architecture = getCurrentArchitecture()
                    result.success(architecture)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    volumeKeysEnabled = true
                    result.success(null)
                }
                "disable" -> {
                    volumeKeysEnabled = false
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ryan.anymex/utils").setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            android.media.MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(path),
                                null
                            ) { _, _ -> }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SCAN_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "Path cannot be null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_EVENTS).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    volumeEventsSink = events
                }

                override fun onCancel(arguments: Any?) {
                    volumeEventsSink = null
                }
            }
        )
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (volumeKeysEnabled && (event.keyCode == KEYCODE_VOLUME_UP || event.keyCode == KEYCODE_VOLUME_DOWN)) {
            if (event.action == ACTION_DOWN) {
                val direction = if (event.keyCode == KEYCODE_VOLUME_UP) "up" else "down"
                volumeEventsSink?.success(direction)
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    private fun getCurrentArchitecture(): String {
        return try {
            val primaryAbi = Build.SUPPORTED_ABIS?.firstOrNull()
            if (primaryAbi != null) {
                when {
                    primaryAbi.contains("arm64") || primaryAbi.contains("v8a") -> "arm64"
                    primaryAbi.contains("arm") || primaryAbi.contains("v7a") -> "arm32"
                    primaryAbi.contains("x86_64") -> "x86_64"
                    primaryAbi.contains("x86") -> "x86"
                    else -> primaryAbi
                }
            } else {
                getSystemProperty("ro.product.cpu.abi") ?: "unknown"
            }
        } catch (e: Exception) {
            e.printStackTrace()
            "unknown"
        }
    }

    private fun getSystemProperty(property: String): String? {
        return try {
            val process = Runtime.getRuntime().exec("getprop $property")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val result = reader.readLine()
            reader.close()
            process.waitFor()
            result
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}