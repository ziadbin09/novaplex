extension DurationFormatter on Duration {
  String toHhMmSs() {
    final h = inHours;
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String toShortLabel() {
    if (inHours > 0) return '${inHours}h ${inMinutes.remainder(60)}m';
    if (inMinutes > 0) return '${inMinutes}m';
    return '${inSeconds}s';
  }
}

extension FileSizeFormatter on int {
  String toReadableSize() {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
