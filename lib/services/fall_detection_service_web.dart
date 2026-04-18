import 'dart:async';
import 'dart:html' as html;
import 'dart:math';
import 'package:flutter/material.dart';

/// Web implementation for `FallDetectionService`.
/// Uses the browser `devicemotion` events as a lightweight fallback so the
/// app can detect strong movements on devices that expose motion sensors.
class FallDetectionService extends ChangeNotifier {
  Function? onFallDetected;

  StreamSubscription<html.DeviceMotionEvent>? _motionSub;
  DateTime? _lastTrigger;
  final double _accelerationThreshold = 18.0; // m/s² - simple heuristic

  Future<void> loadModel() async {
    // No ML model on web, keep API compatibility.
    return;
  }

  void startListening() {
    // If already listening, ignore
    if (_motionSub != null) return;

    try {
      _motionSub = html.window.onDeviceMotion.listen((event) {
        final acc = event.acceleration ?? event.accelerationIncludingGravity;
        if (acc == null) return;

        final x = acc.x ?? 0.0;
        final y = acc.y ?? 0.0;
        final z = acc.z ?? 0.0;

        final magnitude = sqrt(x * x + y * y + z * z);

        if (magnitude >= _accelerationThreshold) {
          final now = DateTime.now();
          if (_lastTrigger == null ||
              now.difference(_lastTrigger!).inSeconds > 8) {
            _lastTrigger = now;
            try {
              if (onFallDetected != null) onFallDetected!();
            } catch (_) {}
          }
        }
      });
    } catch (e) {
      // Some browsers/platforms don't expose devicemotion; fail silently.
      _motionSub = null;
      print('⚠️ FallDetectionService (web) failed to subscribe: $e');
    }
  }

  void stopListening() {
    _motionSub?.cancel();
    _motionSub = null;
  }

  /// Test helper used only for manual testing in the UI.
  /// Calls the `onFallDetected` callback if set.
  void triggerTestFall() {
    try {
      onFallDetected?.call();
    } catch (_) {}
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
