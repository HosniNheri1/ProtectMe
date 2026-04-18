class User {
  String id;
  String name;
  String email;
  String? phone;
  String? photoUrl;
  DateTime birthDate;
  String? medicalInfo;
  List<String> allergies;
  String? bloodType;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.birthDate,
    this.medicalInfo,
    this.allergies = const [],
    this.bloodType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'birthDate': birthDate.toIso8601String(),
      'medicalInfo': medicalInfo,
      'allergies': allergies,
      'bloodType': bloodType,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      birthDate: DateTime.parse(map['birthDate']),
      medicalInfo: map['medicalInfo'],
      allergies: List<String>.from(map['allergies'] ?? []),
      bloodType: map['bloodType'],
    );
  }
}
