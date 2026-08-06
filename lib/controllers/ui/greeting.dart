import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';

class GreetingController extends GetxController {
  var currentGreeting = ''.obs;
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
    final newGreeting = _calculateGreeting();
    if (currentGreeting.value != newGreeting) {
      currentGreeting.value = newGreeting;
    }
  }

  String _calculateGreeting() {
    final hour = DateTime.now().hour;
    final random = Random();

    if (hour >= 5 && hour < 12) {
      return random.nextBool() ? "Rise and shine" : "Good morning";
    } else if (hour >= 12 && hour < 17) {
      return random.nextBool() ? "Happy snacking" : "Good afternoon";
    } else if (hour >= 17 && hour < 21) {
      return random.nextBool() ? "Keep it chill" : "Good evening";
    } else {
      return random.nextBool() ? "You're up late" : "Goodnight";
    }
  }
}
