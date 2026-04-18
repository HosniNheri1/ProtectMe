import 'package:flutter/material.dart';
import 'package:protectme/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  String? _lastAuthError;

  String? get lastAuthError => _lastAuthError;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // Keys for shared preferences
  static const String _userKey = 'current_user';
  static const String _authStatusKey = 'is_authenticated';

  AuthService() {
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool(_authStatusKey) ?? false;
    final userJson = prefs.getString(_userKey);

    if (isAuthenticated && userJson != null) {
      try {
        final userMap = json.decode(userJson);
        _currentUser = User.fromMap(userMap);
        _isAuthenticated = true;
        notifyListeners();
      } catch (e) {
        // If there's an error loading user data, clear it
        await _clearPersistedData();
      }
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      final userJson = json.encode(_currentUser!.toMap());
      await prefs.setString(_userKey, userJson);
      await prefs.setBool(_authStatusKey, _isAuthenticated);
    } else {
      await _clearPersistedData();
    }
  }

  Future<void> _clearPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_authStatusKey);
  }

  Future<bool> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fb.User? fbUser = cred.user;

      if (fbUser != null) {
        // Charger le profil depuis Firestore
        final userDoc = await _loadUserFromFirestore(fbUser.uid);

        if (userDoc != null) {
          _currentUser = userDoc;
        } else {
          // Créer un profil minimal si non existant
          _currentUser = User(
            id: fbUser.uid,
            name: fbUser.displayName ?? 'Utilisateur',
            email: fbUser.email ?? email,
            phone: fbUser.phoneNumber,
            photoUrl: fbUser.photoURL,
            birthDate: DateTime.now(),
          );

          // Sauvegarder ce profil minimal
          await _saveUserAfterLogin(_currentUser!, fbUser.uid);
        }

        // Mettre à jour lastLogin
        await _updateLastLogin(fbUser.uid);

        _isAuthenticated = true;
        await _saveUserData();
        notifyListeners();
        return true;
      }
      return false;
    } on fb.FirebaseAuthException catch (e) {
      _lastAuthError = '${e.code}: ${e.message}';
      print('Login error: ${_lastAuthError}');
      return false;
    } catch (e) {
      _lastAuthError = e.toString();
      print('Login error: ${_lastAuthError}');
      return false;
    }
  }

  Future<User?> _loadUserFromFirestore(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return User(
          id: data['id'] ?? userId,
          name: data['name'] ?? 'Utilisateur',
          email: data['email'] ?? '',
          phone: data['phone'],
          photoUrl: data['photoUrl'],
          birthDate: data['birthDate'] != null
              ? DateTime.parse(data['birthDate'])
              : DateTime.now(),
          medicalInfo: data['medicalInfo'],
          allergies: List<String>.from(data['allergies'] ?? []),
          bloodType: data['bloodType'],
        );
      }
      return null;
    } catch (e) {
      print('❌ Erreur chargement Firestore: $e');
      return null;
    }
  }

  Future<void> _saveUserAfterLogin(User user, String userId) async {
    final userData = {
      'id': userId,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'photoUrl': user.photoUrl,
      'birthDate': user.birthDate.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };

    await _saveUserToFirestore(userData, userId);
  }

  Future<bool> signup(User user, String password) async {
    try {
      print('📝 Tentative création utilisateur Firebase Auth: ${user.email}');

      // 1. Créer utilisateur dans Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );
      final fb.User? fbUser = cred.user;

      if (fbUser == null) {
        _lastAuthError = 'Erreur: utilisateur Firebase null après création';
        return false;
      }
      print('✅ Utilisateur créé dans Firebase Auth: ${fbUser.uid}');

      // 2. Mettre à jour le display name
      await fbUser.updateDisplayName(user.name);
      print('✅ Display name mis à jour: ${user.name}');

      // 3. Préparer les données pour Firestore
      final userData = {
        'id': fbUser.uid,
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'photoUrl': user.photoUrl,
        'birthDate': user.birthDate.toIso8601String(),
        'medicalInfo': user.medicalInfo,
        'allergies': user.allergies,
        'bloodType': user.bloodType,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'emailVerified': false,
        'emergencyContactsCount': 0,
        'alertsCount': 0,
        'lastLogin': FieldValue.serverTimestamp(),
      };

      // 4. Sauvegarder dans Firestore
      print('📝 Tentative sauvegarde dans Firestore pour ${fbUser.uid}');
      await _saveUserToFirestore(userData, fbUser.uid);
      print('✅ Utilisateur sauvegardé dans Firestore');

      // 5. Mettre à jour l'état local
      _currentUser = User.fromMap(userData);
      _isAuthenticated = true;
      await _saveUserData();
      notifyListeners();

      print('✅ Inscription complète réussie');
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _lastAuthError = '${e.code}: ${e.message}';
      print('❌ Erreur Auth inscription: ${_lastAuthError}');
      return false;
    } on FirebaseException catch (e) {
      _lastAuthError = 'Firestore: ${e.code} - ${e.message}';
      print('❌ Erreur Firestore inscription: ${_lastAuthError}');
      return false;
    } catch (e) {
      _lastAuthError = e.toString();
      print('❌ Erreur inscription: ${_lastAuthError}');
      return false;
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur update lastLogin: $e');
    }
  }

  Future<void> _saveUserToFirestore(
    Map<String, dynamic> userData,
    String userId,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .set(userData, SetOptions(merge: true));

      print('✅ Utilisateur sauvegardé dans Firestore avec ID: $userId');
    } catch (e) {
      print('❌ Erreur sauvegarde Firestore: $e');
      throw e;
    }
  }

  Future<bool> updateUserProfile(User updatedUser) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userData = {
        'name': updatedUser.name,
        'email': updatedUser.email,
        'phone': updatedUser.phone,
        'photoUrl': updatedUser.photoUrl,
        'birthDate': updatedUser.birthDate.toIso8601String(),
        'medicalInfo': updatedUser.medicalInfo,
        'allergies': updatedUser.allergies,
        'bloodType': updatedUser.bloodType,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('users').doc(user.uid).update(userData);

      // Mettre à jour localement
      _currentUser = updatedUser;
      await _saveUserData();
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Erreur update profile: $e');
      return false;
    }
  }

  /// Envoie un email de réinitialisation de mot de passe via Firebase Auth
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _lastAuthError = '${e.code}: ${e.message}';
      print('❌ Erreur sendPasswordResetEmail: ${_lastAuthError}');
      return false;
    } catch (e) {
      _lastAuthError = e.toString();
      print('❌ Erreur sendPasswordResetEmail: ${_lastAuthError}');
      return false;
    }
  }

  /// Vérifie si un email est enregistré dans Firebase Auth
  Future<bool> isEmailRegistered(String email) async {
    // Use Firestore lookup as a reliable alternative to fetching sign-in methods
    try {
      return await isEmailInFirestore(email);
    } catch (e) {
      _lastAuthError = e.toString();
      print('❌ Erreur isEmailRegistered (fallback): ${_lastAuthError}');
      return false;
    }
  }

  /// Vérifie si un email existe dans la collection 'users' de Firestore
  Future<bool> isEmailInFirestore(String email) async {
    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      _lastAuthError = e.toString();
      print('❌ Erreur isEmailInFirestore: ${_lastAuthError}');
      return false;
    }
  }

  // AJOUTER: Récupérer user par ID
  Future<User?> getUserById(String userId) async {
    try {
      return await _loadUserFromFirestore(userId);
    } catch (e) {
      print('❌ Erreur getUserById: $e');
      return null;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Soft delete dans Firestore
      await _db.collection('users').doc(user.uid).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Supprimer de Firebase Auth
      await user.delete();

      // Réinitialiser local
      await logout();

      return true;
    } catch (e) {
      print('❌ Erreur deleteAccount: $e');
      return false;
    }
  }

  // AJOUTER: Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      await _clearPersistedData();
      notifyListeners();
    } catch (e) {
      print('❌ Erreur logout: $e');
    }
  }

  // Public method to update current user
  Future<void> updateCurrentUser(User updatedUser) async {
    _currentUser = updatedUser;
    await _saveUserData();
    notifyListeners();
  }

  // Check if user is already logged in (from stored credentials)
  Future<void> checkAuthStatus() async {
    // For demo, always start unauthenticated
    // In real app, check stored tokens/keys
    _isAuthenticated = false;
    notifyListeners();
  }
}
