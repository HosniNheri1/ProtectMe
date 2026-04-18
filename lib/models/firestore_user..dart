import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class FirestoreUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final DateTime birthDate;
  final String? medicalInfo;
  final List<String> allergies;
  final String? bloodType;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Timestamp? lastLogin;
  final bool isActive;
  final bool emailVerified;
  final int emergencyContactsCount;
  final int alertsCount;

  FirestoreUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.birthDate,
    this.medicalInfo,
    required this.allergies,
    this.bloodType,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.isActive = true,
    this.emailVerified = false,
    this.emergencyContactsCount = 0,
    this.alertsCount = 0,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
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
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLogin': lastLogin ?? FieldValue.serverTimestamp(),
      'isActive': isActive,
      'emailVerified': emailVerified,
      'emergencyContactsCount': emergencyContactsCount,
      'alertsCount': alertsCount,
    };
  }

  // Create from DocumentSnapshot
  factory FirestoreUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FirestoreUser(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      birthDate: data['birthDate'] != null
          ? DateTime.parse(data['birthDate'])
          : DateTime.now(),
      medicalInfo: data['medicalInfo'],
      allergies: List<String>.from(data['allergies'] ?? []),
      bloodType: data['bloodType'],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      lastLogin: data['lastLogin'],
      isActive: data['isActive'] ?? true,
      emailVerified: data['emailVerified'] ?? false,
      emergencyContactsCount: data['emergencyContactsCount'] ?? 0,
      alertsCount: data['alertsCount'] ?? 0,
    );
  }

  // Convert to existing User model
  User toUser() {
    return User(
      id: id,
      name: name,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
      birthDate: birthDate,
      medicalInfo: medicalInfo,
      allergies: allergies,
      bloodType: bloodType,
    );
  }
}
