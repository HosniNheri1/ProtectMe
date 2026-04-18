// Dans sms_service_real.dart ou un nouveau whatsapp_service.dart
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:protectme/services/audio_recorder_service.dart';

class WhatsAppService {
  final AudioRecorderService _audioService = AudioRecorderService();

  Future<File?> recordEmergencyAudio({
    Duration duration = const Duration(seconds: 10),
  }) async {
    try {
      print('Démarrage enregistrement audio...');

      // Version automatique (10 secondes comme dans votre code)
      File audioFile = await _audioService.recordEmergencyAudio();

      print('Audio enregistré: ${audioFile.path}');
      return audioFile;
    } catch (e) {
      print('Erreur enregistrement audio: $e');
      return null;
    }
  }

  // Version avec contrôle manuel (démarrer/stop depuis l'UI)
  Future<void> recordEmergencyAudioManualStart() async {
    try {
      await _audioService.startRecording();
    } catch (e) {
      print('Erreur démarrage enregistrement: $e');
    }
  }

  Future<File?> recordEmergencyAudioManualStop() async {
    try {
      return await _audioService.stopRecording();
    } catch (e) {
      print('Erreur arrêt enregistrement: $e');
      return null;
    }
  }

  Future<bool> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
    bool useWeb = true,
  }) async {
    try {
      // Nettoyer le numéro (retirer le +)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      String url;

      if (useWeb) {
        // Version Web WhatsApp
        url =
            'https://web.whatsapp.com/send?phone=$cleanNumber&text=${Uri.encodeComponent(message)}';
      } else {
        // Version Mobile WhatsApp
        url =
            'whatsapp://send?phone=$cleanNumber&text=${Uri.encodeComponent(message)}';
      }

      print('📱 WhatsApp URL: $url');

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return true;
      } else {
        // Fallback : WhatsApp Web standard
        final webUrl =
            'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';
        if (await canLaunchUrl(Uri.parse(webUrl))) {
          await launchUrl(Uri.parse(webUrl));
          return true;
        }
        return false;
      }
    } catch (e) {
      print('❌ Erreur WhatsApp: $e');
      return false;
    }
  }
}
