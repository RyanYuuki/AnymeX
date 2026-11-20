package fr.g123k.deviceapps.listener;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import androidx.annotation.NonNull;

import java.util.HashSet;
import java.util.Set;

import io.flutter.plugin.common.EventChannel;

public class DeviceAppsChangedListener {

    private final DeviceAppsChangedListenerInterface callback;
    private final Set<EventChannel.EventSink> sinks;

    private BroadcastReceiver appsBroadcastReceiver;

    public DeviceAppsChangedListener(DeviceAppsChangedListenerInterface callback) {
        this.callback = callback;
        this.sinks = new HashSet<>(1);
    }

    public void register(@NonNull Context context, EventChannel.EventSink events) {
        if (appsBroadcastReceiver == null) {
            createBroadcastReceiver();
        }

        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(Intent.ACTION_PACKAGE_ADDED);
        intentFilter.addAction(Intent.ACTION_PACKAGE_REPLACED);
        intentFilter.addAction(Intent.ACTION_PACKAGE_CHANGED);
        intentFilter.addAction(Intent.ACTION_PACKAGE_REMOVED);
        intentFilter.addDataScheme("package");

        sinks.add(events);

        context.registerReceiver(appsBroadcastReceiver, intentFilter);
    }

    private void createBroadcastReceiver() {
        appsBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String packageName = intent.getDataString().replace("package:", "");

                boolean replacing = intent.getExtras().getBoolean(Intent.EXTRA_REPLACING, false);

                switch (intent.getAction()) {
                    case Intent.ACTION_PACKAGE_ADDED:
                        if (!replacing) {
                            onPackageInstalled(packageName);
                        }
                        break;
                    case Intent.ACTION_PACKAGE_REPLACED:
                        onPackageUpdated(packageName);
                        break;
                    case Intent.ACTION_PACKAGE_CHANGED:
                        String[] components = intent.getExtras().getStringArray(Intent.EXTRA_CHANGED_COMPONENT_NAME_LIST);
                        if (components.length == 1 && components[0].equalsIgnoreCase(packageName)) {
                            onPackageChanged(packageName);
                        }
                        break;
                    case Intent.ACTION_PACKAGE_REMOVED:
                        if (!replacing) {
                            onPackageUninstalled(packageName);
                        }
                        break;
                }
            }
        };
    }

    void onPackageInstalled(String packageName) {
        for (EventChannel.EventSink sink : sinks) {
            callback.onPackageInstalled(packageName, sink);
        }
    }

    void onPackageUpdated(String packageName) {
        for (EventChannel.EventSink sink : sinks) {
            callback.onPackageUpdated(packageName, sink);
        }
    }

    void onPackageUninstalled(String packageName) {
        for (EventChannel.EventSink sink : sinks) {
            callback.onPackageUninstalled(packageName, sink);
        }
    }

    void onPackageChanged(String packageName) {
        for (EventChannel.EventSink sink : sinks) {
            callback.onPackageChanged(packageName, sink);
        }
    }

    public void unregister(@NonNull Context context) {
        if (appsBroadcastReceiver != null) {
            context.unregisterReceiver(appsBroadcastReceiver);
        }

        sinks.clear();
    }

}
