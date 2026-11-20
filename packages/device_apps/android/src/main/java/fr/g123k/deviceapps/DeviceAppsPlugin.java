package fr.g123k.deviceapps;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import fr.g123k.deviceapps.listener.DeviceAppsChangedListener;
import fr.g123k.deviceapps.listener.DeviceAppsChangedListenerInterface;
import fr.g123k.deviceapps.utils.AppDataConstants;
import fr.g123k.deviceapps.utils.AppDataEventConstants;
import fr.g123k.deviceapps.utils.IntentUtils;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import static fr.g123k.deviceapps.utils.Base64Utils.encodeToBase64;
import static fr.g123k.deviceapps.utils.DrawableUtils.getBitmapFromDrawable;

/**
 * DeviceAppsPlugin
 */
public class DeviceAppsPlugin implements
        FlutterPlugin,
        MethodCallHandler,
        EventChannel.StreamHandler,
        DeviceAppsChangedListenerInterface {

    private static final String LOG_TAG = "DEVICE_APPS";
    private static final int SYSTEM_APP_MASK = ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP;

    private final AsyncWork asyncWork;

    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private DeviceAppsChangedListener appsListener;


    public DeviceAppsPlugin() {
        this.asyncWork = new AsyncWork();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();

        BinaryMessenger messenger = binding.getBinaryMessenger();
        methodChannel = new MethodChannel(messenger, "g123k/device_apps");
        methodChannel.setMethodCallHandler(this);

        eventChannel = new EventChannel(messenger, "g123k/device_apps_events");
        eventChannel.setStreamHandler(this);
    }

    private Context context;

    @Override
    @SuppressWarnings("ConstantConditions")
    public void onMethodCall(MethodCall call, @NonNull final Result result) {
        switch (call.method) {
            case "getInstalledApps":
                boolean systemApps = call.hasArgument("system_apps") && (Boolean) (call.argument("system_apps"));
                boolean includeAppIcons = call.hasArgument("include_app_icons") && (Boolean) (call.argument("include_app_icons"));
                boolean onlyAppsWithLaunchIntent = call.hasArgument("only_apps_with_launch_intent") && (Boolean) (call.argument("only_apps_with_launch_intent"));
                fetchInstalledApps(systemApps, includeAppIcons, onlyAppsWithLaunchIntent, new InstalledAppsCallback() {
                    @Override
                    public void onInstalledAppsListAvailable(final List<Map<String, Object>> apps) {
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                result.success(apps);
                            }
                        });
                    }
                });
                break;
            case "getApp":
                if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument("package_name").toString())) {
                    result.error("ERROR", "Empty or null package name", null);
                } else {
                    String packageName = call.argument("package_name").toString();
                    boolean includeAppIcon = call.hasArgument("include_app_icon") && (Boolean) (call.argument("include_app_icon"));
                    result.success(getApp(packageName, includeAppIcon));
                }
                break;
            case "isAppInstalled":
                if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument("package_name").toString())) {
                    result.error("ERROR", "Empty or null package name", null);
                } else {
                    String packageName = call.argument("package_name").toString();
                    result.success(isAppInstalled(packageName));
                }
                break;
            case "openApp":
                if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument("package_name").toString())) {
                    result.error("ERROR", "Empty or null package name", null);
                } else {
                    String packageName = call.argument("package_name").toString();
                    result.success(openApp(packageName));
                }
                break;
            case "openAppSettings":
                if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument("package_name").toString())) {
                    result.error("ERROR", "Empty or null package name", null);
                } else {
                    String packageName = call.argument("package_name").toString();
                    result.success(openAppSettings(packageName));
                }
                break;
            case "uninstallApp":
                if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument("package_name").toString())) {
                    result.error("ERROR", "Empty or null package name", null);
                } else {
                    String packageName = call.argument("package_name").toString();
                    result.success(uninstallApp(packageName));
                }
                break;
            default:
                result.notImplemented();
        }
    }

    private void fetchInstalledApps(final boolean includeSystemApps, final boolean includeAppIcons, final boolean onlyAppsWithLaunchIntent, final InstalledAppsCallback callback) {
        asyncWork.run(new Runnable() {

            @Override
            public void run() {
                List<Map<String, Object>> installedApps = getInstalledApps(includeSystemApps, includeAppIcons, onlyAppsWithLaunchIntent);

                if (callback != null) {
                    callback.onInstalledAppsListAvailable(installedApps);
                }
            }

        });
    }

    private List<Map<String, Object>> getInstalledApps(boolean includeSystemApps, boolean includeAppIcons, boolean onlyAppsWithLaunchIntent) {
        if (context == null) {
            Log.e(LOG_TAG, "Context is null");
            return new ArrayList<>(0);
        }

        PackageManager packageManager = context.getPackageManager();
        List<PackageInfo> apps = packageManager.getInstalledPackages(0);
        List<Map<String, Object>> installedApps = new ArrayList<>(apps.size());

        for (PackageInfo packageInfo : apps) {
            if (!includeSystemApps && isSystemApp(packageInfo)) {
                continue;
            }
            if (onlyAppsWithLaunchIntent && packageManager.getLaunchIntentForPackage(packageInfo.packageName) == null) {
                continue;
            }

            Map<String, Object> map = getAppData(packageManager,
                    packageInfo,
                    packageInfo.applicationInfo,
                    includeAppIcons);
            installedApps.add(map);
        }

        return installedApps;
    }

    private boolean openApp(@NonNull String packageName) {
        if (!isAppInstalled(packageName)) {
            Log.w(LOG_TAG, "Application with package name \"" + packageName + "\" is not installed on this device");
            return false;
        }

        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);

        if (IntentUtils.isIntentOpenable(launchIntent, context)) {
            context.startActivity(launchIntent);
            return true;
        }

        return false;
    }

    private boolean openAppSettings(@NonNull String packageName) {
        if (!isAppInstalled(packageName)) {
            Log.w(LOG_TAG, "Application with package name \"" + packageName + "\" is not installed on this device");
            return false;
        }

        Intent appSettingsIntent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        appSettingsIntent.setData(Uri.parse("package:" + packageName));
        appSettingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        if (IntentUtils.isIntentOpenable(appSettingsIntent, context)) {
            context.startActivity(appSettingsIntent);
            return true;
        }

        return false;
    }

    private boolean isSystemApp(PackageInfo pInfo) {
        return (pInfo.applicationInfo.flags & SYSTEM_APP_MASK) != 0;
    }

    private boolean isAppInstalled(@NonNull String packageName) {
        try {
            context.getPackageManager().getPackageInfo(packageName, 0);
            return true;
        } catch (PackageManager.NameNotFoundException ignored) {
            return false;
        }
    }

    private Map<String, Object> getApp(String packageName, boolean includeAppIcon) {
        try {
            PackageManager packageManager = context.getPackageManager();
            PackageInfo packageInfo = packageManager.getPackageInfo(packageName, 0);

            return getAppData(packageManager,
                    packageInfo,
                    packageInfo.applicationInfo,
                    includeAppIcon);
        } catch (PackageManager.NameNotFoundException ignored) {
            return null;
        }
    }

    private Map<String, Object> getAppData(PackageManager packageManager,
                                           PackageInfo pInfo,
                                           ApplicationInfo applicationInfo,
                                           boolean includeAppIcon) {
        Map<String, Object> map = new HashMap<>();
        map.put(AppDataConstants.APP_NAME, pInfo.applicationInfo.loadLabel(packageManager).toString());
        map.put(AppDataConstants.APK_FILE_PATH, applicationInfo.sourceDir);
        map.put(AppDataConstants.PACKAGE_NAME, pInfo.packageName);
        map.put(AppDataConstants.VERSION_CODE, pInfo.versionCode);
        map.put(AppDataConstants.VERSION_NAME, pInfo.versionName);
        map.put(AppDataConstants.DATA_DIR, applicationInfo.dataDir);
        map.put(AppDataConstants.SYSTEM_APP, isSystemApp(pInfo));
        map.put(AppDataConstants.INSTALL_TIME, pInfo.firstInstallTime);
        map.put(AppDataConstants.UPDATE_TIME, pInfo.lastUpdateTime);
        map.put(AppDataConstants.IS_ENABLED, applicationInfo.enabled);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            map.put(AppDataConstants.CATEGORY, pInfo.applicationInfo.category);
        }

        if (includeAppIcon) {
            try {
                Drawable icon = packageManager.getApplicationIcon(pInfo.packageName);
                String encodedImage = encodeToBase64(getBitmapFromDrawable(icon), Bitmap.CompressFormat.PNG, 100);
                map.put(AppDataConstants.APP_ICON, encodedImage);
            } catch (PackageManager.NameNotFoundException ignored) {
            }
        }

        return map;
    }

    private boolean uninstallApp(@NonNull String packageName) {
        if (!isAppInstalled(packageName)) {
            Log.w(LOG_TAG, "Application with package name \"" + packageName + "\" is not installed on this device");
            return false;
        }

        Intent appSettingsIntent = new Intent(Intent.ACTION_DELETE);
        appSettingsIntent.setData(Uri.parse("package:" + packageName));
        appSettingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        if (IntentUtils.isIntentOpenable(appSettingsIntent, context)) {
            context.startActivity(appSettingsIntent);
            return true;
        }

        return false;
    }

    @Override
    public void onListen(Object arguments, final EventChannel.EventSink events) {
        if (context != null) {
            if (appsListener == null) {
                appsListener = new DeviceAppsChangedListener(this);
            }

            appsListener.register(context, events);
        }
    }

    @Override
    public void onPackageInstalled(String packageName, EventChannel.EventSink events) {
        events.success(getListenerData(packageName, AppDataEventConstants.EVENT_TYPE_INSTALLED));
    }

    @Override
    public void onPackageUpdated(String packageName, EventChannel.EventSink events) {
        events.success(getListenerData(packageName, AppDataEventConstants.EVENT_TYPE_UPDATED));
    }

    @Override
    public void onPackageUninstalled(String packageName, EventChannel.EventSink events) {
        events.success(getListenerData(packageName, AppDataEventConstants.EVENT_TYPE_UNINSTALLED));
    }

    @Override
    public void onPackageChanged(String packageName, EventChannel.EventSink events) {
        Map<String, Object> listenerData = getListenerData(packageName, null);

        if (listenerData.get(AppDataConstants.IS_ENABLED) == Boolean.valueOf(true)) {
            listenerData.put(AppDataEventConstants.EVENT_TYPE, AppDataEventConstants.EVENT_TYPE_DISABLED);
        } else {
            listenerData.put(AppDataEventConstants.EVENT_TYPE, AppDataEventConstants.EVENT_TYPE_ENABLED);
        }

        events.success(listenerData);
    }

    Map<String, Object> getListenerData(String packageName, String event) {
        Map<String, Object> data = getApp(packageName, false);

        // The app is not installed
        if (data == null) {
            data = new HashMap<>(2);
            data.put(AppDataEventConstants.PACKAGE_NAME, packageName);
        }

        if (event != null) {
            data.put(AppDataEventConstants.EVENT_TYPE, event);
        }

        return data;
    }

    @Override
    public void onCancel(Object arguments) {
        if (context != null && appsListener != null) {
            appsListener.unregister(context);
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        asyncWork.stop();

        if (methodChannel != null) {
            methodChannel.setMethodCallHandler(null);
            methodChannel = null;
        }

        if (eventChannel != null) {
            eventChannel.setStreamHandler(null);
            eventChannel = null;
        }

        if (appsListener != null) {
            appsListener.unregister(context);
            appsListener = null;
        }

        context = null;
    }
}
