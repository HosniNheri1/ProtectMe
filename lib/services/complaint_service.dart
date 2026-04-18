import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComplaintService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? lastError;
  String? lastDocId;

  /// Soumettre une réclamation dans la collection 'complaints'
  Future<bool> submitComplaint({
    required String subject,
    required String description,
  }) async {
    try {
      lastError = null;
      // Require authenticated user for complaint submissions
      final user = _auth.currentUser;
      if (user == null) {
        lastError = 'Utilisateur non authentifié';
        print('❌ Erreur submitComplaint: $lastError');
        return false;
      }
      final now = DateTime.now();

      final data = {
        'subject': subject,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAt_local': now.toIso8601String(),
        'status': 'open',
        'userId': user.uid,
        'userEmail': user.email,
      };

      final docRef = await _db.collection('complaints').add(data);
      lastDocId = docRef.id;
      print('✅ Complaint created with id: ${lastDocId}');
      return true;
    } catch (e) {
      lastError = e.toString();
      print('❌ Erreur submitComplaint: ${lastError}');
      return false;
    }
  }

  /// Stream des réclamations (pour admin)
  Stream<QuerySnapshot> streamComplaints({int limit = 50}) {
    try {
      return _db
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots();
    } catch (e) {
      lastError = e.toString();
      print('❌ Erreur streamComplaints: $lastError');
      rethrow;
    }
  }

  /// Stream des réclamations pour un utilisateur donné
  Stream<QuerySnapshot> streamUserComplaints(String userId, {int limit = 100}) {
    try {
      print('🔍 ComplaintService - Streaming complaints for user: $userId');
      final stream = _db
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots();

      // Test immédiat pour voir si on peut accéder aux données
      stream.first
          .then((snapshot) {
            print(
              '📊 ComplaintService - Query result: ${snapshot.docs.length} documents',
            );
            for (var doc in snapshot.docs) {
              print(
                '📄 ComplaintService - Doc ID: ${doc.id}, Data: ${doc.data()}',
              );
            }
          })
          .catchError((error) {
            print('❌ ComplaintService - Query error: $error');
          });

      return stream;
    } catch (e) {
      lastError = e.toString();
      print('❌ Erreur streamUserComplaints: $lastError');
      rethrow;
    }
  }

  /// Mettre à jour le statut d'une réclamation
  Future<bool> updateComplaintStatus(String docId, String status) async {
    try {
      await _db.collection('complaints').doc(docId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      lastError = e.toString();
      print('❌ Erreur updateComplaintStatus: $lastError');
      return false;
    }
  }

  /// Ajouter une réponse admin à la réclamation
  Future<bool> addResponse(String docId, String response) async {
    try {
      // timestamp is set by server via FieldValue.serverTimestamp()
      await _db.collection('complaints').doc(docId).update({
        'adminResponse': response,
        'responseViewed': false, // Marquer comme non vue pour l'utilisateur
        'respondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      lastError = e.toString();
      print('❌ Erreur addResponse: $lastError');
      return false;
    }
  }

  /// Supprimer une réclamation
  Future<bool> deleteComplaint(String docId) async {
    try {
      await _db.collection('complaints').doc(docId).delete();
      return true;
    } catch (e) {
      lastError = e.toString();
      print('❌ Erreur deleteComplaint: $lastError');
      return false;
    }
  }

  /// Marquer la réponse admin comme vue par l'utilisateur
  Future<bool> markResponseAsViewed(String docId) async {
    try {
      await _db.collection('complaints').doc(docId).update({
        'responseViewed': true,
        'viewedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      lastError = e.toString();
      print('❌ Erreur markResponseAsViewed: $lastError');
      return false;
    }
  }
}
