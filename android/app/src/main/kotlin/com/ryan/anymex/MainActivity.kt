package com.ryan.anymex

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Rational
import android.view.KeyEvent
import android.view.KeyEvent.ACTION_DOWN
import android.view.KeyEvent.KEYCODE_VOLUME_DOWN
import android.view.KeyEvent.KEYCODE_VOLUME_UP
import androidx.annotation.RequiresApi
import fl.pip.FlPiPActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlPiPActivity() {
    private val CHANNEL = "app/architecture"
    private val VOLUME_CHANNEL = "com.ryan.anymex/volume"
    private val VOLUME_EVENTS = "com.ryan.anymex/volume_events"
    private val PIP_CONTROLS_CHANNEL = "com.ryan.anymex/pip_controls"

    private var volumeKeysEnabled = false
    private var volumeEventsSink: EventChannel.EventSink? = null
    private var pipControlsChannel: MethodChannel? = null

    companion object {
        private const val ACTION_PIP_CONTROL = "com.ryan.anymex.PIP_CONTROL"
        private const val EXTRA_CONTROL_TYPE = "control_type"
        private const val CONTROL_PLAY_PAUSE = 1
        private const val CONTROL_PREVIOUS = 2
        private const val CONTROL_NEXT = 3
        private const val REQUEST_CODE_PLAY_PAUSE = 101
        private const val REQUEST_CODE_PREVIOUS = 102
        private const val REQUEST_CODE_NEXT = 103
    }

    private var isPlaying = true
    private var isAutoPipEnabled = false

    private val pipBroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null || intent.action != ACTION_PIP_CONTROL) return
            when (intent.getIntExtra(EXTRA_CONTROL_TYPE, 0)) {
                CONTROL_PLAY_PAUSE -> {
                    pipControlsChannel?.invokeMethod("togglePlayPause", null)
                }
                CONTROL_PREVIOUS -> {
                    pipControlsChannel?.invokeMethod("previousEpisode", null)
                }
                CONTROL_NEXT -> {
                    pipControlsChannel?.invokeMethod("nextEpisode", null)
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
                            android.media.MediaScannerConnection.scanFile(
                                applicationContext, arrayOf(path), null) { _, _ -> }
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
                        val openByDefaultIntent = Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS).apply {
                            data = packageUri
                        }
                        if (openByDefaultIntent.resolveActivity(packageManager) != null) {
                            startActivity(openByDefaultIntent)
                        } else {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = packageUri
                            })
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_DEFAULT_SETTINGS_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        pipControlsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CONTROLS_CHANNEL)
        pipControlsChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "updatePlaybackState" -> {
                    val playing = call.argument<Boolean>("isPlaying") ?: true
                    val autoPiP = call.argument<Boolean>("enablePiP") ?: false
                    isPlaying = playing
                    isAutoPipEnabled = autoPiP

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        updatePipActions(isAutoPipEnabled)
                    }
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

    override fun onStart() {
        super.onStart()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipBroadcastReceiver, IntentFilter(ACTION_PIP_CONTROL), RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(pipBroadcastReceiver, IntentFilter(ACTION_PIP_CONTROL))
        }
    }

    override fun onStop() {
        super.onStop()
        try {
            unregisterReceiver(pipBroadcastReceiver)
        } catch (_: IllegalArgumentException) {
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: android.content.res.Configuration?) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        if (isInPictureInPictureMode) {
            updatePipActions()
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun updatePipActions(autoEnter: Boolean = isAutoPipEnabled) {
        val actions = ArrayList<RemoteAction>()
        val prevIntent = Intent(ACTION_PIP_CONTROL).apply {
            putExtra(EXTRA_CONTROL_TYPE, CONTROL_PREVIOUS)
            setPackage(packageName)
        }
        val prevPendingIntent = PendingIntent.getBroadcast(
            this, REQUEST_CODE_PREVIOUS, prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        actions.add(
            RemoteAction(
                Icon.createWithResource(this, R.drawable.ic_pip_skip_previous),
                "Previous", "Previous episode", prevPendingIntent
            )
        )

        val playPauseIcon = if (isPlaying) R.drawable.ic_pip_pause else R.drawable.ic_pip_play
        val playPauseLabel = if (isPlaying) "Pause" else "Play"
        val playPauseIntent = Intent(ACTION_PIP_CONTROL).apply {
            putExtra(EXTRA_CONTROL_TYPE, CONTROL_PLAY_PAUSE)
            setPackage(packageName)
        }
        val playPausePendingIntent = PendingIntent.getBroadcast(
            this, REQUEST_CODE_PLAY_PAUSE, playPauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        actions.add(
            RemoteAction(
                Icon.createWithResource(this, playPauseIcon),
                playPauseLabel, "Toggle playback", playPausePendingIntent
            )
        )

        val nextIntent = Intent(ACTION_PIP_CONTROL).apply {
            putExtra(EXTRA_CONTROL_TYPE, CONTROL_NEXT)
            setPackage(packageName)
        }
        val nextPendingIntent = PendingIntent.getBroadcast(
            this, REQUEST_CODE_NEXT, nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        actions.add(
            RemoteAction(
                Icon.createWithResource(this, R.drawable.ic_pip_skip_next),
                "Next", "Next episode", nextPendingIntent
            )
        )

        val paramsBuilder = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(16, 9))
            .setActions(actions)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            paramsBuilder.setAutoEnterEnabled(autoEnter && isPlaying)
        }

        setPictureInPictureParams(paramsBuilder.build())
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            if (isPlaying && isAutoPipEnabled) {
                updatePipActions(isAutoPipEnabled)
                val params = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(16, 9))
                    .build()
                enterPictureInPictureMode(params)
            }
        }
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
