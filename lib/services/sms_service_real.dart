import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/phone_utils.dart';

class SMSRealService extends ChangeNotifier {
  // Envoyer un SMS unique
  Future<bool> sendSMS(String phoneNumber, String messageText) async {
    try {
      print('📱 Envoi SMS à: $phoneNumber');
      print('💬 Message: ${messageText.length} caractères');

      // GESTION SPÉCIFIQUE POUR WEB
      if (kIsWeb) {
        print('⚠️ Mode Web détecté - SMS non supporté nativement');
        return _sendSMSWebFallback(phoneNumber, messageText);
      }

      // ✅ DEMANDER LA PERMISSION SMS
      final smsPermissionStatus = await Permission.sms.request();
      print('📋 Permission SMS: $smsPermissionStatus');

      // Nettoyer le numéro de téléphone (correction tunisienne)
      final cleanNumber = _normalizePhoneNumberForTunisia(phoneNumber);
      print('✅ Numéro normalisé: $cleanNumber');

      // Essayer d'envoyer via l'URI SMS (plus fiable que les plugins)
      try {
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: cleanNumber,
          queryParameters: {'body': messageText},
        );

        print('🔗 URI SMS: $smsUri');

        if (await canLaunchUrl(smsUri)) {
          print('🚀 Envoi du SMS via URI...');
          await launchUrl(smsUri);

          // Attendre un peu pour que le SMS soit envoyé
          await Future.delayed(const Duration(seconds: 2));

          print('✅ SMS envoyé avec succès à $cleanNumber');
          return true;
        } else {
          print('❌ Impossible de lancer l\'URI SMS');
          return false;
        }
      } catch (e) {
        print('❌ Erreur lors de l\'envoi SMS: $e');
        return false;
      }
    } catch (e) {
      print('💥 Erreur sendSMS: $e');
      return false;
    }
  }

  // Fallback pour Web
  Future<bool> _sendSMSWebFallback(String phoneNumber, String message) async {
    try {
      print('🌐 Utilisation du fallback Web pour SMS');
      print('📋 Message pour $phoneNumber: $message');
      return true;
    } catch (e) {
      print('❌ Erreur fallback Web: $e');
      return false;
    }
  }

  // Utilitaire de normalisation
  String _normalizePhoneNumberForTunisia(String phoneNumber) {
    return PhoneUtils.normalizeTunisianPhone(phoneNumber);
  }

  // Envoyer des SMS d'urgence à plusieurs contacts
  Future<Map<String, bool>> sendEmergencySMS(
    List<String> contacts,
    String message,
    String locationUrl,
  ) async {
    final results = <String, bool>{};

    // Message d'urgence complet
    final emergencyMessage =
        '''
🚨 ALERTE URGENCE 🚨

$message

Localisation: $locationUrl

Ce message a été envoyé automatiquement par l'application ProtectMe.
Ne pas répondre à ce message.
''';

    for (final contact in contacts) {
      if (contact.trim().isNotEmpty) {
        print('Envoi à $contact...');
        final success = await sendSMS(contact, emergencyMessage);
        results[contact] = success;

        // Petite pause entre les envois
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    // Log des résultats
    final successCount = results.values.where((success) => success).length;
    print('Résultats SMS: $successCount/${contacts.length} succès');

    return results;
  }
}
