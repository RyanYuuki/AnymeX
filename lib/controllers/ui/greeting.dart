import 'package:anymex/l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';

class GreetingController extends GetxController {
  final currentGreeting =
      Rx<String Function(AppLocalizations)>(_calculateGreeting());
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _updateGreeting();
    _timer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _updateGreeting();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _updateGreeting() {
    currentGreeting.value = _calculateGreeting();
  }

  static String Function(AppLocalizations) _calculateGreeting() {
    final hour = DateTime.now().hour;
    final random = Random();

    if (hour >= 5 && hour < 12) {
      return random.nextBool() ? (l) => l.riseAndShine : (l) => l.goodMorning;
    } else if (hour >= 12 && hour < 17) {
      return random.nextBool() ? (l) => l.happySnacking : (l) => l.goodAfternoon;
    } else if (hour >= 17 && hour < 21) {
      return random.nextBool() ? (l) => l.keepItChill : (l) => l.goodEvening;
    } else {
      return random.nextBool() ? (l) => l.youreUpLate : (l) => l.goodnight;
    }
  }
}
