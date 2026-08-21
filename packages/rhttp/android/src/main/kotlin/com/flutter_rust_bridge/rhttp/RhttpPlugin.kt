package com.flutter_rust_bridge.rhttp

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.atomic.AtomicBoolean

class RhttpPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        private val isInitialized = AtomicBoolean(false)

        init {
            try {
                System.loadLibrary("rhttp")
            } catch (e: Throwable) {
                e.printStackTrace()
            }
        }
    }

    private external fun initAndroid(ctx: Context)
    private external fun deinitAndroid()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        if (isInitialized.compareAndSet(false, true)) {
            try {
                initAndroid(flutterPluginBinding.applicationContext)
            } catch (e: Throwable) {
                e.printStackTrace()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        result.notImplemented()
    }
}
