package fr.g123k.deviceapps;

import java.util.List;
import java.util.Map;

public interface InstalledAppsCallback {

    void onInstalledAppsListAvailable(List<Map<String, Object>> apps);

}
