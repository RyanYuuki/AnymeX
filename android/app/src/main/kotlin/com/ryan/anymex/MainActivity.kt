package com.ryan.anymex

import android.app.PictureInPictureParams
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.util.Rational
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
import android.app.PendingIntent
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.graphics.drawable.Icon

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app/architecture"
    private val VOLUME_CHANNEL = "com.ryan.anymex/volume"
    private val VOLUME_EVENTS = "com.ryan.anymex/volume_events"
    private val PIP_CHANNEL = "com.ryan.anymex/pip"
    private var volumeKeysEnabled = false
    private var volumeEventsSink: EventChannel.EventSink? = null

    private var pipAutoEnterEnabled = false

    private val ACTION_PLAY = "com.ryan.anymex.PIP_PLAY"
    private val ACTION_PAUSE = "com.ryan.anymex.PIP_PAUSE"
    private val ACTION_FORWARD = "com.ryan.anymex.PIP_FORWARD"
    private val ACTION_BACKWARD = "com.ryan.anymex.PIP_BACKWARD"
    private var isPlaying = true

    private val pipReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null) return
            val engine = flutterEngine ?: return
            val methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, PIP_CHANNEL)
            when (intent.action) {
                ACTION_PLAY -> {
                    isPlaying = true
                    methodChannel.invokeMethod("onPipPlay", null)
                    updatePipActions()
                }
                ACTION_PAUSE -> {
                    isPlaying = false
                    methodChannel.invokeMethod("onPipPause", null)
                    updatePipActions()
                }
                ACTION_FORWARD -> {
                    methodChannel.invokeMethod("onPipForward", null)
                }
                ACTION_BACKWARD -> {
                    methodChannel.invokeMethod("onPipBackward", null)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentArchitecture" -> result.success(getCurrentArchitecture())
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> { volumeKeysEnabled = true; result.success(null) }
                "disable" -> { volumeKeysEnabled = false; result.success(null) }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ryan.anymex/utils").setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            android.media.MediaScannerConnection.scanFile(applicationContext, arrayOf(path), null) { _, _ -> }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SCAN_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "Path cannot be null", null)
                    }
                }
                "openOpenByDefaultSettings" -> {
                    try {
                        val packageUri = Uri.parse("package:$packageName")
                        val intent = Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS).apply { data = packageUri }
                        if (intent.resolveActivity(packageManager) != null) {
                            startActivity(intent)
                        } else {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply { data = packageUri })
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_DEFAULT_SETTINGS_FAILED", e.message, null)
                    }
                }
                "openWithMime" -> {
                    val url = call.argument<String>("url")
                    val mimeType = call.argument<String>("mimeType")
                    if (url != null && mimeType != null) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(Uri.parse(url), mimeType)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                val headers = call.argument<Map<String, String>>("headers")
                                if (headers != null) {
                                    val bundle = android.os.Bundle()
                                    headers.forEach { (k, v) -> bundle.putString(k, v) }
                                    putExtra("headers", bundle)
                                }
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URL and MIME type required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPipAvailable" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                }
                "isPipActive" -> {
                    val active = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isInPictureInPictureMode
                    result.success(active)
                }
                "enterPip" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val w = call.argument<Int>("width") ?: 16
                            val h = call.argument<Int>("height") ?: 9
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(w, h))
                                .build()
                            enterPictureInPictureMode(params)
                            updatePipActions()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("PIP_ERROR", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "setAutoEnter" -> {
                    pipAutoEnterEnabled = call.argument<Boolean>("enabled") ?: false
                    result.success(null)
                }
                "updatePlaybackState" -> {
                    val playing = call.argument<Boolean>("playing") ?: true
                    isPlaying = playing
                    updatePipActions()
                    result.success(null)
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

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipReceiver, IntentFilter().apply {
                addAction(ACTION_PLAY)
                addAction(ACTION_PAUSE)
                addAction(ACTION_FORWARD)
                addAction(ACTION_BACKWARD)
            }, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(pipReceiver, IntentFilter().apply {
                addAction(ACTION_PLAY)
                addAction(ACTION_PAUSE)
                addAction(ACTION_FORWARD)
                addAction(ACTION_BACKWARD)
            })
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(pipReceiver)
        } catch (_: Exception) {}
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (pipAutoEnterEnabled && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                enterPictureInPictureMode(
                    PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9)).build()
                )
                updatePipActions()
            } catch (_: Exception) {}
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: android.content.res.Configuration?) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        val engine = flutterEngine
        if (engine != null) {
            val methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, PIP_CHANNEL)
            methodChannel.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
        }
        if (isInPictureInPictureMode) {
            updatePipActions()
        }
    }

    private fun updatePipActions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val actions = ArrayList<RemoteAction>()

            val backwardIntent = PendingIntent.getBroadcast(
                this, 1, Intent(ACTION_BACKWARD).apply { setPackage(packageName) }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val backwardAction = RemoteAction(
                Icon.createWithResource(this, android.R.drawable.ic_media_rew),
                "Rewind", "Rewind", backwardIntent
            )
            actions.add(backwardAction)

            if (isPlaying) {
                val pauseIntent = PendingIntent.getBroadcast(
                    this, 2, Intent(ACTION_PAUSE).apply { setPackage(packageName) }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                val pauseAction = RemoteAction(
                    Icon.createWithResource(this, android.R.drawable.ic_media_pause),
                    "Pause", "Pause", pauseIntent
                )
                actions.add(pauseAction)
            } else {
                val playIntent = PendingIntent.getBroadcast(
                    this, 3, Intent(ACTION_PLAY).apply { setPackage(packageName) }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                val playAction = RemoteAction(
                    Icon.createWithResource(this, android.R.drawable.ic_media_play),
                    "Play", "Play", playIntent
                )
                actions.add(playAction)
            }

            val forwardIntent = PendingIntent.getBroadcast(
                this, 4, Intent(ACTION_FORWARD).apply { setPackage(packageName) }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val forwardAction = RemoteAction(
                Icon.createWithResource(this, android.R.drawable.ic_media_ff),
                "Forward", "Forward", forwardIntent
            )
            actions.add(forwardAction)

            val params = PictureInPictureParams.Builder()
                .setActions(actions)
                .setAspectRatio(Rational(16, 9))
                .build()
            setPictureInPictureParams(params)
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (volumeKeysEnabled && (event.keyCode == KEYCODE_VOLUME_UP || event.keyCode == KEYCODE_VOLUME_DOWN)) {
            if (event.action == ACTION_DOWN) {
                volumeEventsSink?.success(if (event.keyCode == KEYCODE_VOLUME_UP) "up" else "down")
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    private fun getCurrentArchitecture(): String {
        return try {
            val abi = Build.SUPPORTED_ABIS?.firstOrNull()
            when {
                abi == null -> getSystemProperty("ro.product.cpu.abi") ?: "unknown"
                abi.contains("arm64") || abi.contains("v8a") -> "arm64"
                abi.contains("arm") || abi.contains("v7a") -> "arm32"
                abi.contains("x86_64") -> "x86_64"
                abi.contains("x86") -> "x86"
                else -> abi
            }
        } catch (e: Exception) {
            e.printStackTrace()
            "unknown"
        }
    }

    private fun getSystemProperty(property: String): String? {
        return try {
            val process = Runtime.getRuntime().exec("getprop $property")
            val result = BufferedReader(InputStreamReader(process.inputStream)).readLine()
            process.waitFor()
            result
        } catch (e: Exception) {
            null
        }
    }
}