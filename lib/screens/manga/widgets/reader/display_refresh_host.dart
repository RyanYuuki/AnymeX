import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/database/data_keys/keys.dart';

class DisplayRefreshHost {
  final RxBool isFlashing = false.obs;
  final RxString flashColor = 'black'.obs;
  final RxInt flashDurationMs = 200.obs;
  final RxInt flashInterval = 1.obs;

  int _callCount = 0;
  Timer? _timer;

  void loadPreferences() {
    flashColor.value = ReaderKeys.displayRefreshColor.get<String>('black');
    flashDurationMs.value = ReaderKeys.displayRefreshDurationMs.get<int>(200);
    flashInterval.value = ReaderKeys.displayRefreshInterval.get<int>(1);
  }

  void savePreferences() {
    ReaderKeys.displayRefreshColor.set(flashColor.value);
    ReaderKeys.displayRefreshDurationMs.set(flashDurationMs.value);
    ReaderKeys.displayRefreshInterval.set(flashInterval.value);
  }
  
  void flash() {
    _callCount++;
    if (_callCount % flashInterval.value != 0) return;

    _timer?.cancel();
    isFlashing.value = true;

    _timer = Timer(Duration(milliseconds: flashDurationMs.value), () {
      isFlashing.value = false;
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}

class DisplayRefreshOverlay extends StatelessWidget {
  const DisplayRefreshOverlay({super.key, required this.host});

  final DisplayRefreshHost host;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!host.isFlashing.value) return const SizedBox.shrink();
      return IgnorePointer(
        child: Container(
          color: host.flashColor.value == 'white' ? Colors.white : Colors.black,
        ),
      );
    });
  }
}
