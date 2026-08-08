class PlayerUtils {
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    if (duration.inHours < 1) {
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }

    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
