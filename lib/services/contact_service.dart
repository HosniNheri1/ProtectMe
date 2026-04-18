import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:protectme/models/emergency_contact.dart';
import '../utils/phone_utils.dart';

class ContactService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<EmergencyContact> _contacts = [];
  bool _isLoading = false;

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  bool get isLoading => _isLoading;

  // Initialiser et charger les contacts
  Future<void> initialize() async {
    await loadContacts();
  }

  // Charger les contacts depuis Firestore
  Future<void> loadContacts() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        _contacts = [];
        return;
      }

      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .where('isActive', isEqualTo: true)
          .orderBy('priority')
          .get();

      _contacts = snapshot.docs.map((doc) {
        final data = doc.data();
        return EmergencyContact(
          id: doc.id,
          name: data['name'] ?? 'Contact',
          phone: data['phone'] ?? '',
          email: data['email'],
          relationship: data['relationship'],
          priority: data['priority'] ?? 1,
          receivesSMS: data['receivesSMS'] ?? true,
          receivesCall: data['receivesCall'] ?? true,
          isActive: data['isActive'] ?? true,
          addedDate: _parseFirestoreDate(data['addedDate']),
        );
      }).toList();

      print('✅ ${_contacts.length} contacts chargés');
    } catch (e) {
      print('❌ Erreur chargement contacts: $e');
      _contacts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime _parseFirestoreDate(dynamic dateData) {
    try {
      if (dateData == null) return DateTime.now();

      if (dateData is Timestamp) {
        return dateData.toDate();
      } else if (dateData is String) {
        return DateTime.parse(dateData);
      } else if (dateData is DateTime) {
        return dateData;
      } else {
        print('⚠️ Format de date inattendu: ${dateData.runtimeType}');
        return DateTime.now();
      }
    } catch (e) {
      print('⚠️ Erreur parsing date: $e');
      return DateTime.now();
    }
  }

  // Ajouter un nouveau contact
  Future<bool> addContact(EmergencyContact contact) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return false;
      }

      // VÉRIFICATION DES DOUBLONS
      final normalizedPhone = PhoneUtils.normalizeTunisianPhone(contact.phone);

      // Vérifier dans la liste locale
      if (_contacts.any(
        (c) => PhoneUtils.normalizeTunisianPhone(c.phone) == normalizedPhone,
      )) {
        print('❌ Contact déjà existant: ${contact.phone}');
        return false;
      }

      // Vérifier dans Firestore pour être sûr
      final duplicateQuery = await _db
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .where('phone', isEqualTo: normalizedPhone)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (duplicateQuery.docs.isNotEmpty) {
        print('❌ Contact déjà dans Firestore: ${contact.phone}');
        return false;
      }

      print('✅ Numéro unique vérifié: $normalizedPhone');

      // Générer un ID unique
      final docRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc();

      final contactWithId = contact.copyWith(id: docRef.id);

      // Sauvegarder avec le numéro normalisé
      await docRef.set({
        ...contactWithId.toMap(),
        'phone': normalizedPhone, // Sauvegarder le numéro normalisé
        'phoneOriginal': contact.phone, // Garder l'original pour affichage
        'addedDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recharger les contacts
      await loadContacts();

      print('✅ Contact ajouté: ${contact.name} ($normalizedPhone)');
      return true;
    } catch (e) {
      print('❌ Erreur ajout contact: $e');
      return false;
    }
  }

  // Mettre à jour un contact existant
  Future<bool> updateContact(String id, EmergencyContact contact) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(id)
          .update({
            ...contact.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Recharger les contacts
      await loadContacts();

      print('✅ Contact mis à jour: ${contact.name}');
      return true;
    } catch (e) {
      print('❌ Erreur mise à jour contact: $e');
      return false;
    }
  }

  // Supprimer un contact (soft delete)
  Future<bool> deleteContact(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(id)
          .update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Recharger les contacts
      await loadContacts();

      print('✅ Contact supprimé');
      return true;
    } catch (e) {
      print('❌ Erreur suppression contact: $e');
      return false;
    }
  }

  // Vérifier si le numéro existe déjà
  bool contactExists(String phoneNumber) {
    final normalized = PhoneUtils.normalizeTunisianPhone(phoneNumber);
    return _contacts.any(
      (contact) =>
          PhoneUtils.normalizeTunisianPhone(contact.phone) == normalized,
    );
  }

  // Obtenir le prochain numéro de priorité disponible
  int getNextPriority() {
    if (_contacts.isEmpty) return 1;
    return _contacts.map((c) => c.priority).reduce((a, b) => a > b ? a : b) + 1;
  }
}
