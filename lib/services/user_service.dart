import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/firestore_user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Récupérer l'utilisateur courant depuis Firestore
  Future<FirestoreUser?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return FirestoreUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur getCurrentUser: $e');
      return null;
    }
  }

  // Mettre à jour le profil
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _db.collection('users').doc(user.uid).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ Erreur updateProfile: $e');
      return false;
    }
  }

  // Vérifier si l'email existe déjà
  Future<bool> checkEmailExists(String email) async {
    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erreur checkEmailExists: $e');
      return false;
    }
  }

  // Récupérer plusieurs utilisateurs
  Future<List<FirestoreUser>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final query = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      return query.docs.map((doc) => FirestoreUser.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Erreur getUsersByIds: $e');
      return [];
    }
  }

  // Compter les utilisateurs actifs
  Future<int> getActiveUsersCount() async {
    try {
      final query = await _db
          .collection('users')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      print('❌ Erreur getActiveUsersCount: $e');
      return 0;
    }
  }

  // Rechercher des utilisateurs
  Future<List<FirestoreUser>> searchUsers(String queryText) async {
    try {
      // Firestore nécessite des index pour les recherches de texte
      // Pour l'instant, recherche basique sur le nom
      final query = await _db
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: queryText)
          .where('name', isLessThanOrEqualTo: queryText + '\uf8ff')
          .limit(20)
          .get();

      return query.docs.map((doc) => FirestoreUser.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Erreur searchUsers: $e');
      return [];
    }
  }

  // Mettre à jour le compteur de contacts d'urgence
  Future<void> updateEmergencyContactsCount(int count) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _db.collection('users').doc(user.uid).update({
        'emergencyContactsCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur updateEmergencyContactsCount: $e');
    }
  }

  // Mettre à jour le compteur d'alertes
  Future<void> incrementAlertsCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _db.collection('users').doc(user.uid).update({
        'alertsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur incrementAlertsCount: $e');
    }
  }

  // Récupérer tous les utilisateurs (limité)
  Future<List<FirestoreUser>> getAllUsers({int limit = 100}) async {
    try {
      final query = await _db.collection('users').limit(limit).get();
      return query.docs.map((d) => FirestoreUser.fromFirestore(d)).toList();
    } catch (e) {
      print('❌ Erreur getAllUsers: $e');
      return [];
    }
  }

  // Définir le rôle d'un utilisateur (e.g. 'admin' ou 'user')
  Future<bool> setUserRole(String uid, String role) async {
    try {
      await _db.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ Erreur setUserRole: $e');
      return false;
    }
  }

  /// Envoyer un email de réinitialisation de mot de passe
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('❌ Erreur sendPasswordResetEmail: $e');
      return false;
    }
  }
}
