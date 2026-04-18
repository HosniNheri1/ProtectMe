enum AlertType { manual, inactivity, fall, anomaly, location, health }

enum AlertStatus { pending, confirmed, cancelled, escalated, resolved }

class Alert {
  String id;
  AlertType type;
  AlertStatus status;
  DateTime timestamp;
  String? location;
  double? latitude;
  double? longitude;
  String? message;
  List<String> contactedNumbers;
  List<String> confirmedContacts;
  bool biometricConfirmed;
  String? audioRecordingUrl;
  Map<String, dynamic>? sensorData;

  Alert({
    required this.id,
    required this.type,
    required this.status,
    required this.timestamp,
    this.location,
    this.latitude,
    this.longitude,
    this.message,
    this.contactedNumbers = const [],
    this.confirmedContacts = const [],
    this.biometricConfirmed = false,
    this.audioRecordingUrl,
    this.sensorData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'status': status.toString(),
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'message': message,
      'contactedNumbers': contactedNumbers,
      'confirmedContacts': confirmedContacts,
      'biometricConfirmed': biometricConfirmed,
      'audioRecordingUrl': audioRecordingUrl,
      'sensorData': sensorData,
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      type: AlertType.values.firstWhere((e) => e.toString() == map['type']),
      status: AlertStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
      ),
      timestamp: DateTime.parse(map['timestamp']),
      location: map['location'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      message: map['message'],
      contactedNumbers: List<String>.from(map['contactedNumbers'] ?? []),
      confirmedContacts: List<String>.from(map['confirmedContacts'] ?? []),
      biometricConfirmed: map['biometricConfirmed'] ?? false,
      audioRecordingUrl: map['audioRecordingUrl'],
      sensorData: map['sensorData'],
    );
  }
}
