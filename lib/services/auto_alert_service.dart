import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:protectme/models/alert.dart';
import 'alert_service.dart';
import 'fall_detection_service.dart';
import 'notification_service.dart';
import 'package:protectme/utils/app_navigator.dart';

class AutoAlertService extends ChangeNotifier {
  final FallDetectionService _fallDetectionService;
  final AlertService _alertService;
  final NotificationService _notificationService;

  StreamSubscription<String>? _cancelSubscription;

  // Paramètres par défaut
  int _inactivityTimeoutDaySeconds = 10; // 10 s par défaut
  int _inactivityTimeoutNightSeconds = 10; // 10 s par défaut
  int _dayStartHour = 6;
  int _dayEndHour = 22;
  int _networkLossTimeoutSeconds = 5;

  bool _fallDetectionEnabled = false;
  bool _inactivityDetectionEnabled = false;
  bool _networkLossDetectionEnabled = false;

  double _movementThreshold = 0.5;
  double get movementThreshold => _movementThreshold;

  // État interne
  Timer? _inactivityTimer;
  Timer? _networkTimer;
  bool _wasConnected = true;
  bool _isAlertTriggered = false;

  // Pending alerts map pour annulation
  final Map<String, Timer> _pendingAlerts = {};

  // Getters
  int get inactivityTimeoutDaySeconds => _inactivityTimeoutDaySeconds;
  int get inactivityTimeoutNightSeconds => _inactivityTimeoutNightSeconds;
  int get networkLossTimeoutSeconds => _networkLossTimeoutSeconds;
  bool get fallDetectionEnabled => _fallDetectionEnabled;
  bool get inactivityDetectionEnabled => _inactivityDetectionEnabled;
  bool get networkLossDetectionEnabled => _networkLossDetectionEnabled;
  int get dayStartHour => _dayStartHour;
  int get dayEndHour => _dayEndHour;

  AutoAlertService(
    this._fallDetectionService,
    this._alertService,
    this._notificationService,
  ) {
    // Load preferences first, then initialize sensors/timers so defaults
    // from SharedPreferences (or our false defaults) are respected.
    _loadPreferences().then((_) => _init());

    // S'abonner aux annulations provenant du service de notifications
    _cancelSubscription = _notificationService.cancelStream.listen((alertId) {
      _handleCancel(alertId);
    });
  }

  void _handleCancel(String alertId) {
    _pendingAlerts[alertId]?.cancel();
    _pendingAlerts.remove(alertId);
    _isAlertTriggered = false;
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Migration: when changing default behavior, ensure existing users get
    // the new defaults only once. This avoids forcing changes on every start.
    const migrationKey = 'autoAlertsDefaultMigrated';
    if (prefs.getBool(migrationKey) != true) {
      // Set automatic alerts defaults to false for existing installs.
      await prefs.setBool('fallDetectionEnabled', false);
      await prefs.setBool('inactivityDetectionEnabled', false);
      await prefs.setBool('networkLossDetectionEnabled', false);
      await prefs.setBool(migrationKey, true);
      debugPrint(
        '[AutoAlertService] Applied auto-alerts default migration -> all auto alerts disabled',
      );
    }
    _inactivityTimeoutDaySeconds = prefs.getInt('inactivityTimeoutDay') ?? 10;
    _inactivityTimeoutNightSeconds =
        prefs.getInt('inactivityTimeoutNight') ?? 10;
    _networkLossTimeoutSeconds = prefs.getInt('networkLossTimeout') ?? 5;
    _fallDetectionEnabled = prefs.getBool('fallDetectionEnabled') ?? false;
    _inactivityDetectionEnabled =
        prefs.getBool('inactivityDetectionEnabled') ?? false;
    _networkLossDetectionEnabled =
        prefs.getBool('networkLossDetectionEnabled') ?? false;
    _dayStartHour = prefs.getInt('dayStartHour') ?? 6;
    _dayEndHour = prefs.getInt('dayEndHour') ?? 22;
    notifyListeners();
    // Ensure timers reflect loaded preferences (cancel/restart inactivity timer if needed).
    _resetInactivityTimer();
  }

  void cancelAlert(String alertId) {
    _handleCancel(alertId);
  }

  void _showConfirmationNotificationWithTimer(AlertType type, String message) {
    // If the alert type is inactivity but the detection is disabled, ignore.
    if (type == AlertType.inactivity && !_inactivityDetectionEnabled) {
      debugPrint(
        '[AutoAlertService] Inactivity alert suppressed because inactivityDetectionEnabled=false',
      );
      return;
    }

    if (_isAlertTriggered) return; // évite les doublons
    _isAlertTriggered = true;
    debugPrint(
      '[AutoAlertService] _showConfirmationNotificationWithTimer: type=${type.name} message="$message"',
    );

    final String alertId = DateTime.now().millisecondsSinceEpoch.toString();

    // If we have a foreground context, show an in-app confirmation dialog
    // with a short countdown (5s). Otherwise fall back to notification.
    final ctx = appNavigatorKey.currentContext;
    debugPrint(
      '[AutoAlertService] appNavigatorKey.currentContext is ${ctx == null ? 'NULL' : 'available'}',
    );
    if (ctx != null) {
      debugPrint('[AutoAlertService] Showing in-app confirmation dialog');
      // In-app confirmation
      _pendingAlerts[alertId] = Timer(Duration.zero, () {}); // placeholder

      final completer = Completer<bool>();
      int secondsLeft = 5;
      Timer? countdownLocal;
      StateSetter? setStateRef;

      showDialog<bool>(
            context: ctx,
            barrierDismissible: false,
            builder: (dialogCtx) {
              int localSeconds = secondsLeft;
              return StatefulBuilder(
                builder: (contextSB, setState) {
                  setStateRef ??= setState;
                  if (countdownLocal == null) {
                    countdownLocal = Timer.periodic(
                      const Duration(seconds: 1),
                      (_) {
                        localSeconds -= 1;
                        try {
                          setStateRef?.call(() {});
                        } catch (_) {}
                        if (localSeconds <= 0) {
                          countdownLocal?.cancel();
                          if (Navigator.of(dialogCtx).canPop())
                            Navigator.of(dialogCtx).pop(false);
                        }
                      },
                    );
                  }

                  final displayBody = _localizedMessage(type);

                  return AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            type == AlertType.location
                                ? 'Network Lost'
                                : '${_humanReadableType(type)} detected',
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayBody),
                        SizedBox(height: 8),
                        Text('The alert will be sent in $localSeconds s.'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          countdownLocal?.cancel();
                          Navigator.of(contextSB).pop(true);
                        },
                        child: Text('Cancel'),
                      ),
                    ],
                  );
                },
              );
            },
          )
          .then((cancelled) {
            if (countdownLocal != null && countdownLocal!.isActive)
              countdownLocal?.cancel();
            if (cancelled == true) {
              // user cancelled
              _isAlertTriggered = false;
              _pendingAlerts.remove(alertId);
              notifyListeners();
              completer.complete(false);
            } else {
              completer.complete(true);
            }
          })
          .catchError((_) {
            if (countdownLocal != null && countdownLocal!.isActive)
              countdownLocal?.cancel();
            if (!completer.isCompleted) completer.complete(true);
          });

      // After dialog completes, send alert if not cancelled
      completer.future.then((shouldSend) async {
        if (shouldSend) {
          // We already showed an in-app confirmation dialog here in AutoAlertService.
          // Avoid showing a second confirmation inside AlertService by not
          // passing a UI context.
          await _alertService.triggerAutomaticAlert(type);
        }
        _isAlertTriggered = false;
        _pendingAlerts.remove(alertId);
        notifyListeners();
      });

      return;
    }

    // Fallback: show notification with cancel action
    debugPrint(
      '[AutoAlertService] No UI context — using notification fallback and starting confirmation timer (${_networkLossTimeoutSeconds}s)',
    );
    final Timer confirmationTimer = Timer(Duration(seconds: 5), () {
      debugPrint(
        '[AutoAlertService] confirmation timer fired — triggering automatic alert',
      );
      _alertService.triggerAutomaticAlert(type);
      _pendingAlerts.remove(alertId);
      _isAlertTriggered = false;
      notifyListeners();
    });

    _pendingAlerts[alertId] = confirmationTimer;

    debugPrint(
      '[AutoAlertService] Calling NotificationService.showConfirmationNotification with payload=$alertId',
    );
    final notifBody = _localizedMessage(type);
    _notificationService.showConfirmationNotification(
      title: '${_humanReadableType(type)} detected',
      body: notifBody,
      payload: alertId,
      onCancel: (id) {
        // optional callback used by NotificationService
        cancelAlert(id);
      },
    );
  }

  String _localizedMessage(AlertType type) {
    switch (type) {
      case AlertType.inactivity:
        return 'Prolonged inactivity. Cancel if you are present.';
      case AlertType.location:
        return 'Network lost. Cancel if you are in a no-service area.';
      case AlertType.fall:
        return 'Fall detected. Cancel if you are OK.';
      case AlertType.anomaly:
        return 'Anomaly detected. Cancel if this is a false alarm.';
      case AlertType.health:
        return 'Health issue detected. Cancel if you are OK.';
      case AlertType.manual:
        return 'Automatic alert detected.';
    }
  }

  Future<void> updatePreferences({
    double? movementThreshold,
    int? inactivityTimeoutDay,
    int? inactivityTimeoutNight,
    int? networkLossTimeout,
    bool? fallDetection,
    bool? inactivityDetection,
    bool? networkLossDetection,
    int? dayStartHour,
    int? dayEndHour,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (movementThreshold != null) {
      _movementThreshold = movementThreshold;
      await prefs.setDouble('movementThreshold', movementThreshold);
    }
    if (inactivityTimeoutDay != null) {
      _inactivityTimeoutDaySeconds = inactivityTimeoutDay;
      await prefs.setInt('inactivityTimeoutDay', inactivityTimeoutDay);
    }
    if (inactivityTimeoutNight != null) {
      _inactivityTimeoutNightSeconds = inactivityTimeoutNight;
      await prefs.setInt('inactivityTimeoutNight', inactivityTimeoutNight);
    }
    if (networkLossTimeout != null) {
      _networkLossTimeoutSeconds = networkLossTimeout;
      await prefs.setInt('networkLossTimeout', networkLossTimeout);
    }
    if (fallDetection != null) {
      _fallDetectionEnabled = fallDetection;
      await prefs.setBool('fallDetectionEnabled', fallDetection);
    }
    if (inactivityDetection != null) {
      _inactivityDetectionEnabled = inactivityDetection;
      await prefs.setBool('inactivityDetectionEnabled', inactivityDetection);
    }
    if (networkLossDetection != null) {
      _networkLossDetectionEnabled = networkLossDetection;
      await prefs.setBool('networkLossDetectionEnabled', networkLossDetection);
    }
    if (dayStartHour != null) {
      _dayStartHour = dayStartHour;
      await prefs.setInt('dayStartHour', dayStartHour);
    }
    if (dayEndHour != null) {
      _dayEndHour = dayEndHour;
      await prefs.setInt('dayEndHour', dayEndHour);
    }
    notifyListeners();
    _resetInactivityTimer();
  }

  void _init() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      _onMovement(event);
    });

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _onConnectivityChanged(result != ConnectivityResult.none);
    });

    _fallDetectionService.onFallDetected = _triggerFallAlert;

    _resetInactivityTimer();
  }

  int _getCurrentInactivityTimeout() {
    final now = DateTime.now();
    final hour = now.hour;
    if (hour >= _dayStartHour && hour < _dayEndHour) {
      return _inactivityTimeoutDaySeconds;
    } else {
      return _inactivityTimeoutNightSeconds;
    }
  }

  void _onMovement(AccelerometerEvent event) {
    if (!_inactivityDetectionEnabled) return;
    double magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    const double gravity = 9.81;
    if ((magnitude - gravity).abs() > _movementThreshold) {
      _resetInactivityTimer();
    }
  }

  void _resetInactivityTimer() {
    // If inactivity detection is disabled, ensure no timer is running.
    if (!_inactivityDetectionEnabled) {
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
      return;
    }

    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      Duration(seconds: _getCurrentInactivityTimeout()),
      () {
        _showConfirmationNotificationWithTimer(
          AlertType.inactivity,
          'Prolonged inactivity. Cancel if you are present.',
        );
      },
    );
  }

  String _humanReadableType(AlertType type) {
    switch (type) {
      case AlertType.manual:
        return 'Manual alert';
      case AlertType.inactivity:
        return 'Inactivity';
      case AlertType.fall:
        return 'Fall';
      case AlertType.anomaly:
        return 'Anomaly';
      case AlertType.location:
        return 'Location';
      case AlertType.health:
        return 'Health';
    }
  }

  void _onConnectivityChanged(bool isConnected) {
    if (!_networkLossDetectionEnabled) return;
    // Debug logging to trace connectivity state and timers
    debugPrint(
      '[AutoAlertService] _onConnectivityChanged: isConnected=$isConnected, wasConnected=$_wasConnected',
    );

    if (!isConnected && _wasConnected) {
      debugPrint(
        '[AutoAlertService] Network lost — starting network timer (${_networkLossTimeoutSeconds}s)',
      );
      _networkTimer?.cancel();
      _networkTimer = Timer(Duration(seconds: _networkLossTimeoutSeconds), () {
        debugPrint(
          '[AutoAlertService] Network timer fired — showing confirmation notification',
        );
        _showConfirmationNotificationWithTimer(
          AlertType.location,
          'Network lost. Cancel if you are in a no-service area.',
        );
      });
    } else if (isConnected && !_wasConnected) {
      debugPrint(
        '[AutoAlertService] Network restored — cancelling network timer',
      );
      _networkTimer?.cancel();
    }
    _wasConnected = isConnected;
  }

  void _triggerFallAlert() {
    if (!_fallDetectionEnabled || _isAlertTriggered) return;
    _showConfirmationNotificationWithTimer(
      AlertType.fall,
      'Fall detected. Cancel if you are OK.',
    );
  }

  void startMonitoring() {
    _resetInactivityTimer();
  }

  void stopMonitoring() {
    _inactivityTimer?.cancel();
    _networkTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscription?.cancel();
    stopMonitoring();
    super.dispose();
  }
}
