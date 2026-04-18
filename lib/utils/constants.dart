class AppConstants {
  // API Keys
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String firebaseWebApiKey = 'YOUR_FIREBASE_WEB_API_KEY';

  // URLs
  static const String privacyPolicyUrl =
      'https://protectme.example.com/privacy';
  static const String termsOfServiceUrl = 'https://protectme.example.com/terms';
  static const String supportEmail = 'support@protectme.example.com';

  // Timeouts
  static const int inactivityTimeoutMinutes = 15;
  static const int confirmationTimeoutSeconds = 30;
  static const int locationUpdateIntervalSeconds = 60;

  // Thresholds
  static const double fallDetectionThreshold = 15.0; // m/s²
  static const int maxEmergencyContacts = 5;
  static const int minBatteryLevelForMonitoring = 20; // percentage

  // Messages
  static const String defaultEmergencyMessage =
      'URGENCE: J\'ai besoin d\'aide ! Ma position: {location}';
  static const String defaultSafetyMessage =
      'Je suis en sécurité. Désolé pour la fausse alerte.';

  // Colors
  static const int primaryColor = 0xFFE53935; // Red
  static const int secondaryColor = 0xFF1976D2; // Blue
  static const int successColor = 0xFF4CAF50; // Green
  static const int warningColor = 0xFFFF9800; // Orange
  static const int dangerColor = 0xFFD32F2F; // Dark Red

  // Storage keys
  static const String userPrefsKey = 'user_preferences';
  static const String contactsKey = 'emergency_contacts';
  static const String settingsKey = 'app_settings';
  static const String alertsKey = 'alerts_history';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String alertsCollection = 'alerts';
  static const String devicesCollection = 'devices';

  // Audio settings
  static const int audioSampleRate = 44100;
  static const int audioBitRate = 128000;
  static const int maxRecordingDurationSeconds = 30;

  // Notification channels
  static const String emergencyChannelId = 'emergency_alerts';
  static const String emergencyChannelName = 'Alertes d\'urgence';
  static const String emergencyChannelDescription =
      'Notifications pour les alertes d\'urgence';

  static const String monitoringChannelId = 'monitoring_alerts';
  static const String monitoringChannelName = 'Surveillance';
  static const String monitoringChannelDescription =
      'Notifications de surveillance d\'activité';

  // Location settings
  static const double locationAccuracy = 10.0; // meters
  static const int locationDistanceFilter = 10; // meters
  static const Duration locationUpdateInterval = Duration(seconds: 60);

  // Sensor settings
  static const int sensorSamplingRate = 50; // Hz
  static const int sensorBufferSize = 100;
}

class Routes {
  static const String home = '/';
  static const String profile = '/profile';
  static const String contacts = '/contacts';
  static const String settings = '/settings';
  static const String alerts = '/alerts';
  static const String manualAlert = '/manual-alert';
  static const String addContact = '/add-contact';
  static const String editProfile = '/edit-profile';
  static const String privacy = '/privacy';
  static const String biometricSetup = '/biometric-setup';
  static const String login = '/login';
  static const String register = '/register';
}
