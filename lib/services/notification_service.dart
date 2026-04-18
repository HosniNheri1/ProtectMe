import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// permission_handler not required here; UI handles requesting permissions

class NotificationService {
  final _cancelStreamController = StreamController<String>.broadcast();
  Stream<String> get cancelStream => _cancelStreamController.stream;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == 'cancel_action') {
          _cancelStreamController.add(response.payload ?? '');
        }
        // Handle notification tap if needed
      },
    );
  }

  // Dans NotificationService
  Future<void> showConfirmationNotification({
    required String title,
    required String body,
    required String payload,
    required Function onCancel,
  }) async {
    print(
      '[NotificationService] showConfirmationNotification: title="$title" body="$body" payload=$payload',
    );

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'protectme_channel',
      'ProtectMe Alerts',
      channelDescription: 'Emergency alerts from ProtectMe',
      importance: Importance.max,
      priority: Priority.high,
    );

    var iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      categoryIdentifier: 'alert_category',
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Afficher la notification
    await _flutterLocalNotificationsPlugin.show(
      1, // id unique pour cette notification
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    // Gérer le tap sur l'action (nécessite un callback global)
    // On utilise le onDidReceiveNotificationResponse dans initialize
  }

  void dispose() {
    _cancelStreamController.close();
  }

  // Permission helper removed (handled in UI code)

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'protectme_channel',
          'ProtectMe Alerts',
          channelDescription: 'Emergency alerts from ProtectMe',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> showInactivityAlert() async {
    await showNotification(
      title: 'Inactivity alert',
      body: 'No activity detected. Alert triggered automatically.',
    );
  }

  Future<void> showManualAlertTriggered() async {
    await showNotification(
      title: 'Manual alert triggered',
      body: 'Your emergency alert has been sent to contacts.',
    );
  }

  Future<void> showFallDetected() async {
    await showNotification(
      title: 'Fall detected',
      body: 'A fall was detected. Alert sent automatically.',
    );
  }
}
