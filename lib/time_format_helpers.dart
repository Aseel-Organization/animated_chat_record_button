String formatTime(int seconds) {
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  int secs = seconds % 60;
  if (minutes >= 60) {
    return '${hours.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitMinutes:$twoDigitSeconds";
}
