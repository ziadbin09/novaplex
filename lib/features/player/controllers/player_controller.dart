import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../data/models/video_file.dart';

enum ZoomMode { fit, fill, crop }
enum LoopMode { off, loopOne }

class PlayerController extends ChangeNotifier {
  PlayerController(this.video, bool hardwareDecode,
      {List<double> eqBands = const [0.0, 0.0, 0.0, 0.0, 0.0]}) {
    _init(hardwareDecode, eqBands);
  }

  final VideoFile video;
  late final Player player;
  late final VideoController videoController;

  bool showControls = true;
  bool isFullscreen = false;
  ZoomMode zoomMode = ZoomMode.fit;
  double playbackSpeed = 1.0;
  bool isLocked = false;
  LoopMode loopMode = LoopMode.off;
  bool orientationLocked = false;

  /// Pinch-to-zoom scale applied to the video surface (1.0 = normal)
  double videoScale = 1.0;

  /// Currently active subtitle track
  SubtitleTrack currentSubtitle = SubtitleTrack.no();

  /// Sleep timer countdown — null when no timer is set
  Duration? sleepTimerRemaining;
  bool _sleepOnVideoEnd = false;
  bool get sleepOnVideoEnd => _sleepOnVideoEnd;

  /// True once an "end of video" sleep timer has fired —
  /// blocks auto-play-next from advancing afterwards.
  bool didSleepAtEnd = false;

  /// A-B repeat points — both null = off, A only = armed, A+B = looping
  Duration? abPointA;
  Duration? abPointB;
  StreamSubscription<Duration>? _abSub;

  /// Audio/subtitle sync delays in seconds
  double subtitleDelay = 0.0;
  double audioDelay = 0.0;

  /// Software volume boost: 0.0 = none, 1.0 = +100% (i.e. 200% total)
  double volumeBoost = 0.0;

  /// Show the playback stats overlay
  bool showStats = false;

  Timer? _hideTimer;
  Timer? _sleepTimer;
  StreamSubscription<bool>? _completedSub;

  Future<void> _init(bool hardwareDecode, List<double> eqBands) async {
    player = Player();
    // Hardware decoding renders a frozen frame on emulators (BlueStacks) —
    // honour the setting; software decode is the safe default
    videoController = VideoController(
      player,
      configuration: VideoControllerConfiguration(
        enableHardwareAcceleration: hardwareDecode,
      ),
    );
    await WakelockPlus.enable();
    final platform = player.platform;
    if (platform is NativePlayer) {
      await platform.setProperty('volume-max', '200');
    }
    // Apply persisted EQ on startup
    await setEq(eqBands);
    await player.open(Media(video.path));
    _startHideTimer();
    // Listen for video end to handle "end of video" sleep timer
    _completedSub = player.stream.completed.listen((completed) {
      if (completed && _sleepOnVideoEnd) {
        _sleepOnVideoEnd = false;
        didSleepAtEnd = true;
        cancelSleepTimer();
      }
    });
    notifyListeners();
  }

  // ── Controls visibility ──────────────────────────────────────────────────

  void toggleControls() {
    if (isLocked) return;
    showControls = !showControls;
    if (showControls) _startHideTimer();
    notifyListeners();
  }

  void showControlsTemporary() {
    if (isLocked) return;
    showControls = true;
    _startHideTimer();
    notifyListeners();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      showControls = false;
      notifyListeners();
    });
  }

  void cancelHideTimer() => _hideTimer?.cancel();

  // ── Playback controls ────────────────────────────────────────────────────

  void setZoomMode(ZoomMode mode) {
    zoomMode = mode;
    notifyListeners();
  }

  void setPlaybackSpeed(double speed) {
    playbackSpeed = speed;
    player.setRate(speed);
    notifyListeners();
  }

  void toggleLock() {
    isLocked = !isLocked;
    showControls = !isLocked;
    notifyListeners();
  }

  /// Lock screen rotation to the current orientation, or unlock.
  Future<void> toggleOrientationLock(Orientation current) async {
    orientationLocked = !orientationLocked;
    if (orientationLocked) {
      await SystemChrome.setPreferredOrientations(
        current == Orientation.landscape
            ? [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : [DeviceOrientation.portraitUp],
      );
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    notifyListeners();
  }

  /// Pinch-to-zoom: set absolute scale, clamped to a sensible range.
  void setVideoScale(double scale) {
    videoScale = scale.clamp(0.5, 3.0);
    notifyListeners();
  }

  void resetVideoScale() {
    videoScale = 1.0;
    notifyListeners();
  }

  void toggleLoop() {
    loopMode = loopMode == LoopMode.off ? LoopMode.loopOne : LoopMode.off;
    player.setPlaylistMode(
        loopMode == LoopMode.loopOne ? PlaylistMode.single : PlaylistMode.none);
    notifyListeners();
  }

  /// Seek to [position] once the player has buffered enough.
  Future<void> resumeTo(Duration position) async {
    if (position <= Duration.zero) return;
    await Future.delayed(const Duration(milliseconds: 600));
    await player.seek(position);
  }

  /// Set a subtitle track and notify listeners.
  void setSubtitleTrack(SubtitleTrack track) {
    currentSubtitle = track;
    player.setSubtitleTrack(track);
    notifyListeners();
  }

  Future<void> toggleFullscreen() async {
    isFullscreen = !isFullscreen;
    if (isFullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    notifyListeners();
  }

  void seekBy(int seconds) {
    final current = player.state.position;
    final target = current + Duration(seconds: seconds);
    player.seek(target.isNegative ? Duration.zero : target);
    showControlsTemporary();
  }

  // ── A-B repeat ───────────────────────────────────────────────────────────

  /// Cycle: off → A set → A-B looping → off
  void cycleAbRepeat() {
    if (abPointA == null) {
      abPointA = player.state.position;
    } else if (abPointB == null) {
      final pos = player.state.position;
      if (pos > abPointA! + const Duration(seconds: 1)) {
        abPointB = pos;
        _abSub = player.stream.position.listen((p) {
          if (abPointA != null && abPointB != null && p >= abPointB!) {
            player.seek(abPointA!);
          }
        });
      } else {
        // B must be after A — restart selection
        abPointA = player.state.position;
      }
    } else {
      clearAbRepeat();
      return;
    }
    notifyListeners();
  }

  void clearAbRepeat() {
    abPointA = null;
    abPointB = null;
    _abSub?.cancel();
    _abSub = null;
    notifyListeners();
  }

  // ── Volume boost & stats ─────────────────────────────────────────────────

  /// [boost] 0.0–1.0 maps to 100%–200% mpv software volume.
  void setVolumeBoost(double boost) {
    volumeBoost = boost.clamp(0.0, 1.0);
    player.setVolume(100 + volumeBoost * 100);
    notifyListeners();
  }

  void toggleStats() {
    showStats = !showStats;
    notifyListeners();
  }

  // ── Equalizer ────────────────────────────────────────────────────────────

  /// Apply 5-band EQ (Bass ~62Hz, Low-Mid ~250Hz, Mid ~1kHz,
  /// High-Mid ~4kHz, Treble ~16kHz) via mpv's 10-band equalizer.
  /// Values in dB (-12 to +12). All-zero removes the filter.
  Future<void> setEq(List<double> bands) async {
    final platform = player.platform;
    if (platform is! NativePlayer) return;
    final allZero = bands.every((b) => b == 0.0);
    if (allZero) {
      await platform.setProperty('af', '');
      return;
    }
    final b = List<double>.filled(10, 0.0);
    b[1] = bands[0]; // 62 Hz  – Bass
    b[3] = bands[1]; // 250 Hz – Low-Mid
    b[5] = bands[2]; // 1 kHz  – Mid
    b[7] = bands[3]; // 4 kHz  – High-Mid
    b[9] = bands[4]; // 16 kHz – Treble
    final gains = b.map((v) => v.toStringAsFixed(1)).join(':');
    await platform.setProperty('af', 'equalizer=$gains');
  }

  // ── Audio / subtitle sync ────────────────────────────────────────────────

  Future<void> setSubtitleDelay(double seconds) async {
    subtitleDelay = (seconds * 10).roundToDouble() / 10;
    final platform = player.platform;
    if (platform is NativePlayer) {
      await platform.setProperty(
          'sub-delay', subtitleDelay.toStringAsFixed(1));
    }
    notifyListeners();
  }

  Future<void> setAudioDelay(double seconds) async {
    audioDelay = (seconds * 10).roundToDouble() / 10;
    final platform = player.platform;
    if (platform is NativePlayer) {
      await platform.setProperty(
          'audio-delay', audioDelay.toStringAsFixed(1));
    }
    notifyListeners();
  }

  // ── Sleep timer ──────────────────────────────────────────────────────────

  void setSleepTimer(Duration duration) {
    _sleepOnVideoEnd = false;
    sleepTimerRemaining = duration;
    _sleepTimer?.cancel();
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (sleepTimerRemaining == null) return;
      final next = sleepTimerRemaining! - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        sleepTimerRemaining = null;
        _sleepTimer?.cancel();
        player.pause();
      } else {
        sleepTimerRemaining = next;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void setSleepTimerEndOfVideo() {
    _sleepOnVideoEnd = true;
    sleepTimerRemaining = null;
    _sleepTimer?.cancel();
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepOnVideoEnd = false;
    sleepTimerRemaining = null;
    _sleepTimer?.cancel();
    notifyListeners();
  }

  // ── Dispose ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _hideTimer?.cancel();
    _sleepTimer?.cancel();
    _abSub?.cancel();
    _completedSub?.cancel();
    player.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
