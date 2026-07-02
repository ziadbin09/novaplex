/// Guards against the same navigation action firing twice in quick
/// succession — e.g. a double-tap on a video tile that would otherwise
/// push two PlayerScreens (and spin up two video decoders) on top of
/// each other.
class NavDebounce {
  NavDebounce._();

  static DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
  static const _window = Duration(milliseconds: 700);

  /// Returns true once per debounce window. Call immediately before
  /// navigating; a second call within [_window] returns false.
  static bool allow() {
    final now = DateTime.now();
    if (now.difference(_lastPush) < _window) return false;
    _lastPush = now;
    return true;
  }
}
