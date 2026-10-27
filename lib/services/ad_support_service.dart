import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AdSupportService with WidgetsBindingObserver {
  AdSupportService._() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final AdSupportService instance = AdSupportService._();

  static const String adUrl = 'https://uplcm.com/4/12135636';
  static const int minWatchSeconds = 5;

  final RxInt watchedCount = General.watchedAdsCount.get<int>(0).obs;
  DateTime? _launchTime;
  DateTime? _leaveTime;
  bool _isWatching = false;

  Future<void> watchAd() async {
    final uri = Uri.parse(adUrl);
    _isWatching = true;
    _leaveTime = null;
    _launchTime = DateTime.now();

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _isWatching = false;
        snackBar('Could not open ad link');
      }
    } catch (_) {
      _isWatching = false;
      snackBar('Could not open ad link');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_isWatching && _leaveTime == null) {
        _leaveTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isWatching) {
        _isWatching = false;
        final leftAt = _leaveTime ?? _launchTime;
        _leaveTime = null;
        _launchTime = null;

        if (leftAt != null) {
          final elapsed = DateTime.now().difference(leftAt).inSeconds;
          if (elapsed >= minWatchSeconds) {
            final newCount = watchedCount.value + 1;
            General.watchedAdsCount.set(newCount);
            watchedCount.value = newCount;
            snackBar(
              'Ad watch verified ($newCount total)! Points will be rewarded in the next update.',
            );
          } else {
            snackBar(
              'Returned too quickly (${elapsed}s). Watch for at least ${minWatchSeconds}s to verify.',
            );
          }
        }
      }
    }
  }
}
