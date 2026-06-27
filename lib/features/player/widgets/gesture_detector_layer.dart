import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';
import '../controllers/player_controller.dart';

// Native brightness channel — no external package needed
class _BrightnessChannel {
  static const _ch = MethodChannel('com.novaplex/brightness');

  static Future<double> get() async {
    try {
      final v = await _ch.invokeMethod<double>('getBrightness');
      return (v ?? 0.5).clamp(0.0, 1.0);
    } catch (_) {
      return 0.5;
    }
  }

  static Future<void> set(double value) async {
    try {
      await _ch.invokeMethod('setBrightness', {'brightness': value.clamp(0.0, 1.0)});
    } catch (_) {}
  }
}

class GestureDetectorLayer extends StatefulWidget {
  const GestureDetectorLayer({
    super.key,
    required this.controller,
    required this.enableBrightness,
    required this.enableVolume,
    required this.enableSeek,
    required this.skipSeconds,
    required this.child,
  });

  final PlayerController controller;
  final bool enableBrightness;
  final bool enableVolume;
  final bool enableSeek;
  final int skipSeconds;
  final Widget child;

  @override
  State<GestureDetectorLayer> createState() => _GestureDetectorLayerState();
}

class _GestureDetectorLayerState extends State<GestureDetectorLayer> {
  String? _indicator;
  double _indicatorValue = 0;
  IconData _indicatorIcon = Icons.volume_up;

  double _startBrightness = 0.5;
  double _startVolume = 0.5;
  int _seekDelta = 0;

  // Scale-gesture state: pan axis is locked once movement passes a threshold
  _PanAxis? _panAxis;
  double _accumDx = 0;
  double _accumDy = 0;
  double _startScale = 1.0;

  DateTime _lastTap = DateTime(0);
  Offset _lastTapPos = Offset.zero;
  int _tapCount = 0;

  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showIndicator(String text, double value, IconData icon) {
    if (!mounted) return;
    _hideTimer?.cancel();
    if (_indicator != text || _indicatorValue != value || _indicatorIcon != icon) {
      setState(() {
        _indicator = text;
        _indicatorValue = value;
        _indicatorIcon = icon;
      });
    }
    _hideTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _indicator = null);
    });
  }

  void _onTap(TapDownDetails details) {
    final now = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;
    final x = details.localPosition.dx;

    if (now.difference(_lastTap).inMilliseconds < 350 &&
        (details.localPosition - _lastTapPos).distance < 60) {
      _tapCount++;
      if (_tapCount >= 2) {
        _tapCount = 0;
        if (x < screenWidth / 2) {
          widget.controller.seekBy(-widget.skipSeconds);
          _showIndicator('-${widget.skipSeconds}s', 0, Icons.fast_rewind_rounded);
        } else {
          widget.controller.seekBy(widget.skipSeconds);
          _showIndicator('+${widget.skipSeconds}s', 0, Icons.fast_forward_rounded);
        }
        HapticFeedback.lightImpact();
        return;
      }
    } else {
      _tapCount = 1;
    }
    _lastTap = now;
    _lastTapPos = details.localPosition;

    Future.delayed(const Duration(milliseconds: 350), () {
      if (_tapCount == 1) {
        widget.controller.toggleControls();
        _tapCount = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: _onTap,
          onScaleStart: (d) async {
            _panAxis = null;
            _accumDx = 0;
            _accumDy = 0;
            _seekDelta = 0;
            _startScale = widget.controller.videoScale;
            _startBrightness = await _BrightnessChannel.get();
            // Suppress Android system volume popup during swipe gestures
            VolumeController.instance.showSystemUI = false;
            // Combined level: 0..1 device volume, 1..2 software boost
            _startVolume = await VolumeController.instance.getVolume() +
                widget.controller.volumeBoost;
          },
          onScaleUpdate: (d) {
            // Two fingers → pinch-to-zoom the video
            if (d.pointerCount >= 2) {
              _panAxis = _PanAxis.pinch;
              final newScale = (_startScale * d.scale).clamp(0.5, 3.0);
              widget.controller.setVideoScale(newScale);
              _showIndicator(
                '${(newScale * 100).round()}%',
                0,
                Icons.zoom_out_map_rounded,
              );
              return;
            }
            if (_panAxis == _PanAxis.pinch) return;

            // One finger → lock onto an axis once movement is significant
            _accumDx += d.focalPointDelta.dx;
            _accumDy += d.focalPointDelta.dy;
            if (_panAxis == null) {
              if (_accumDx.abs() > 12 || _accumDy.abs() > 12) {
                _panAxis = _accumDx.abs() > _accumDy.abs()
                    ? _PanAxis.horizontal
                    : _PanAxis.vertical;
              } else {
                return;
              }
            }

            final screenW = MediaQuery.of(context).size.width;
            final screenH = MediaQuery.of(context).size.height;

            if (_panAxis == _PanAxis.vertical) {
              final delta = -d.focalPointDelta.dy / screenH;
              final x = d.focalPoint.dx;
              if (x < screenW / 2 && widget.enableBrightness) {
                final newVal = (_startBrightness + delta * 2).clamp(0.0, 1.0);
                _BrightnessChannel.set(newVal);
                _startBrightness = newVal;
                _showIndicator(
                  '${(newVal * 100).round()}%',
                  newVal,
                  newVal > 0.5 ? Icons.brightness_high : Icons.brightness_low,
                );
              } else if (x >= screenW / 2 && widget.enableVolume) {
                // 0..1 = device volume, 1..2 = software boost up to 200%
                final newVal = (_startVolume + delta * 2).clamp(0.0, 2.0);
                if (newVal <= 1.0) {
                  VolumeController.instance.setVolume(newVal);
                  widget.controller.setVolumeBoost(0);
                } else {
                  VolumeController.instance.setVolume(1.0);
                  widget.controller.setVolumeBoost(newVal - 1.0);
                }
                _startVolume = newVal;
                _showIndicator(
                  '${(newVal * 100).round()}%',
                  newVal / 2,
                  newVal > 1.0
                      ? Icons.volume_up_rounded
                      : newVal > 0.5
                          ? Icons.volume_up
                          : (newVal > 0
                              ? Icons.volume_down
                              : Icons.volume_off),
                );
              }
            } else if (_panAxis == _PanAxis.horizontal && widget.enableSeek) {
              _seekDelta += (d.focalPointDelta.dx / screenW * 120).round();
              _showIndicator(
                '${_seekDelta >= 0 ? '+' : ''}${_seekDelta}s',
                0,
                _seekDelta >= 0
                    ? Icons.fast_forward_rounded
                    : Icons.fast_rewind_rounded,
              );
            }
          },
          onScaleEnd: (_) {
            if (_panAxis == _PanAxis.horizontal &&
                widget.enableSeek &&
                _seekDelta != 0) {
              widget.controller.seekBy(_seekDelta);
            }
            // Snap back to normal when the pinch ends close to 1×
            if (_panAxis == _PanAxis.pinch &&
                (widget.controller.videoScale - 1.0).abs() < 0.15) {
              widget.controller.resetVideoScale();
            }
            _panAxis = null;
            // Restore system UI for hardware volume buttons
            VolumeController.instance.showSystemUI = true;
          },
          onLongPressStart: (_) {
            widget.controller.player.setRate(2.0);
            _showIndicator('2×', 0, Icons.speed);
          },
          onLongPressEnd: (_) {
            widget.controller.player.setRate(widget.controller.playbackSpeed);
            if (mounted) setState(() => _indicator = null);
          },
        ),

        if (_indicator != null)
          Positioned(
            // Dock brightness to left side, volume to right, seek stays centre
            left: _indicatorIcon == Icons.brightness_high ||
                    _indicatorIcon == Icons.brightness_low
                ? 20
                : null,
            right: _indicatorIcon == Icons.volume_up ||
                    _indicatorIcon == Icons.volume_up_rounded ||
                    _indicatorIcon == Icons.volume_down ||
                    _indicatorIcon == Icons.volume_off
                ? 20
                : null,
            top: 0,
            bottom: 0,
            child: Center(
              child: _GestureIndicator(
                icon: _indicatorIcon,
                label: _indicator!,
                value: _indicatorValue,
              ),
            ),
          ),
      ],
    );
  }
}

enum _PanAxis { vertical, horizontal, pinch }

class _GestureIndicator extends StatelessWidget {
  const _GestureIndicator(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          if (value > 0) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
