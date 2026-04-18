import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUser {
  String id;
  String name;
  String email;
  String? phone;
  String? photoUrl;
  DateTime birthDate;
  String? medicalInfo;
  List<String> allergies;
  String? bloodType;
  String role;
  bool isActive;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  FirestoreUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.birthDate,
    this.medicalInfo,
    this.allergies = const [],
    this.bloodType,
    this.role = 'user',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  // Factory constructor to create FirestoreUser from Firestore document
  factory FirestoreUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return FirestoreUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      birthDate: data['birthDate'] != null
          ? DateTime.parse(data['birthDate'].toString())
          : DateTime.now(),
      medicalInfo: data['medicalInfo'],
      allergies: List<String>.from(data['allergies'] ?? []),
      bloodType: data['bloodType'],
      isActive: data['isActive'] ?? true,
      role: data['role'] ?? 'user',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'photoUrl': photoUrl,
      'birthDate': birthDate.toIso8601String(),
      'medicalInfo': medicalInfo,
      'allergies': allergies,
      'bloodType': bloodType,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
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
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // Factory constructor from JSON
  factory FirestoreUser.fromJson(Map<String, dynamic> json) {
    return FirestoreUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      photoUrl: json['photoUrl'],
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'].toString())
          : DateTime.now(),
      medicalInfo: json['medicalInfo'],
      allergies: List<String>.from(json['allergies'] ?? []),
      bloodType: json['bloodType'],
      isActive: json['isActive'] ?? true,
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'].toString())
          : null,
    );
  }
}
