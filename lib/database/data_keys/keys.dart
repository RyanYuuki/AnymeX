import 'package:anymex/database/kv_helper.dart';

enum General { shouldAskForTrack, hideAdultContent, uiScaler }

enum PlayerKeys { useLibass, useMediaKit }

enum DynamicKeys {
  trackingPermission,
  watchProgress,
  customSetting;

  T get<T>(dynamic id, T defaultVal) {
    return KvHelper.get<T>('${name}_$id', defaultVal: defaultVal);
  }

  void set<T>(dynamic id, T value) {
    KvHelper.set('${name}_$id', value);
  }

  void delete(dynamic id) {
    KvHelper.remove('${name}_$id');
  }
}

// for contibutors
// use em like this


// GET
// General.shouldAskForTrack.get(false);

// SET 
// General.shouldAskForTrack.set(true);

// DELETE (its just there for the sack of it, no need to use this)
// General.shouldAskForTrack.delete();

// Dynamic Keys are for when you want to store different values for different things

// for example
// DynamicKeys.trackingPermission.set("21", false); // Tracking permmission fals for one pixel