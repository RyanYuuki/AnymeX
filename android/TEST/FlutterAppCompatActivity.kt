package com.ryan.anymex

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.FrameLayout
import android.view.View
import android.view.ViewGroup
import androidx.appcompat.app.AppCompatActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.FlutterEngineConfigurator
import io.flutter.embedding.android.FlutterEngineProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

open class FlutterAppCompatActivity : AppCompatActivity(),
    FlutterEngineProvider,
    FlutterEngineConfigurator {

    companion object {
        private val FRAGMENT_CONTAINER_ID = View.generateViewId()
        private const val TAG_FLUTTER_FRAGMENT = "flutter_fragment"
    }

    protected var flutterFragment: FlutterFragment? = null

    val flutterEngine: FlutterEngine?
        get() = flutterFragment?.flutterEngine


    override fun onCreate(savedInstanceState: Bundle?) {
        flutterFragment = supportFragmentManager
            .findFragmentByTag(TAG_FLUTTER_FRAGMENT) as? FlutterFragment

        super.onCreate(savedInstanceState)

        val container = FrameLayout(this).apply {
            id = FRAGMENT_CONTAINER_ID
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        setContentView(container)

        if (flutterFragment == null) {
            flutterFragment = FlutterFragment.createDefault()
            supportFragmentManager.beginTransaction()
                .add(FRAGMENT_CONTAINER_ID, flutterFragment!!, TAG_FLUTTER_FRAGMENT)
                .commit()
        }

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
        override fun handleOnBackPressed() {
            val engine = flutterEngine
            if (engine != null) {
                engine.navigationChannel.popRoute()
            } else {
                isEnabled = false
                onBackPressedDispatcher.onBackPressed()
            }
        }
        })
    }

    override fun onPostResume() {
        super.onPostResume()
        flutterFragment?.onPostResume()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        flutterFragment?.onNewIntent(intent)
    }

    @Deprecated("Use ActivityResultLauncher instead")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        flutterFragment?.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        flutterFragment?.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        flutterFragment?.onUserLeaveHint()
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        flutterFragment?.onTrimMemory(level)
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {}
}
