package fr.g123k.deviceapps.listener;

import io.flutter.plugin.common.EventChannel;

public interface DeviceAppsChangedListenerInterface {

    void onPackageInstalled(String packageName, EventChannel.EventSink events);

    void onPackageUpdated(String packageName, EventChannel.EventSink events);

    void onPackageUninstalled(String packageName, EventChannel.EventSink events);

    void onPackageChanged(String packageName, EventChannel.EventSink events);

}
