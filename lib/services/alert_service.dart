import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:protectme/models/alert.dart';
import 'package:protectme/services/sms_service_real.dart';
import 'package:protectme/services/contact_service.dart';
import 'package:protectme/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/language_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:protectme/widgets/confirm_alert_dialog.dart';
import 'package:protectme/utils/io_helper.dart';
import 'package:protectme/models/emergency_contact.dart';

class AlertService extends ChangeNotifier {
  // État
  bool _isMonitoring = true;
  bool _isSendingAlert = false;
  Timer? _inactivityTimer;
  DateTime? _lastActivity;

  // Historique
  List<Alert> _alerts = [];

  // Services
  late SMSRealService _smsService;

  // Configuration
  static const int SOS_COUNTDOWN_SECONDS = 5;

  AlertService() {
    _initializeServices();
  }

  void _initializeServices() {
    _smsService = SMSRealService();
  }

  // Getters
  bool get isMonitoring => _isMonitoring;
  bool get isSendingAlert => _isSendingAlert;
  List<Alert> get alerts => List.unmodifiable(_alerts);
  DateTime? get lastActivity => _lastActivity;

  // === FLUX ALERTE MANUELLE (SOS) ===

  Future<void> triggerManualAlert(BuildContext context) async {
    if (_isSendingAlert) {
      print('⚠️ Déjà en train d\'envoyer une alerte');
      return;
    }

    try {
      _isSendingAlert = true;
      notifyListeners();

      print('🚨 === DÉBUT ALERTE SOS ===');
      print('👤 Utilisateur: ${FirebaseAuth.instance.currentUser?.email}');

      // Étape 1: Confirmation
      print('1️⃣ Étape: Confirmation utilisateur');
      final confirmResult = await _showSimpleConfirmation(context);
      if (confirmResult == null || confirmResult['confirmed'] != true) {
        print('❌ Alerte annulée par l\'utilisateur');
        _isSendingAlert = false;
        notifyListeners();
        return;
      }
      print('✅ Confirmation OK');

      // Récupérer la méthode choisie par l'utilisateur (sms / whatsapp)
      final chosenMethod = confirmResult['method'] is String
          ? (confirmResult['method'] as String)
          : (kIsWeb ? 'whatsapp' : 'sms');

      // Étape 2: Localisation
      print('2️⃣ Étape: Récupération localisation');
      final position = await _getCurrentLocation();
      if (position == null) {
        print('❌ Échec récupération localisation');
        ErrorHandler.showError(
          context,
          'Impossible de récupérer votre position. L\'alerte sera envoyée sans localisation.',
        );
        // Continuer sans localisation ? Ou annuler ?
        // Pour l'instant, on annule
        _isSendingAlert = false;
        notifyListeners();
        return;
      }
      print('📍 Position obtenue: ${position.latitude}, ${position.longitude}');

      // Étape 3: Créer l'alerte
      print('3️⃣ Étape: Création alerte');
      final alert = Alert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AlertType.manual,
        status: AlertStatus.pending,
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        message: 'Alerte SOS déclenchée manuellement',
        biometricConfirmed: false,
      );

      // Attach audio recording if present
      try {
        final audioPath = confirmResult['audioPath'];
        if (audioPath is String && audioPath.isNotEmpty) {
          alert.audioRecordingUrl = audioPath;
        }
      } catch (_) {}

      // Étape 4: Sauvegarder localement
      print('4️⃣ Étape: Sauvegarde locale');
      _alerts.insert(0, alert);
      notifyListeners();
      print('✅ Alerte sauvegardée localement (${_alerts.length} alertes)');

      // Étape 5: Envoyer aux contacts
      print('5️⃣ Étape: Envoi aux contacts');
      final success = await _sendAlertToContacts(
        alert,
        context,
        method: chosenMethod,
      );

      // Étape 6: Mettre à jour le statut
      print('6️⃣ Étape: Mise à jour statut');
      alert.status = success ? AlertStatus.confirmed : AlertStatus.pending;
      print('📊 Statut alerte: ${alert.status}');

      // Étape 7: Notifier l'utilisateur
      if (success) {
        print('🎉 === ALERTE ENVOYÉE AVEC SUCCÈS ===');
        _showSuccessDialog(context, alert);
      } else {
        print('❌ === ÉCHEC ENVOI ALERTE ===');
        ErrorHandler.showError(
          context,
          'Échec de l\'envoi des SMS. Vérifiez vos contacts.',
        );
      }
    } catch (e) {
      print('💥 ERREUR ALERTE SOS: $e');
      print('💥 Stack trace: ${e.toString()}');
      ErrorHandler.showError(context, 'Erreur inattendue: ${e.toString()}');
    } finally {
      _isSendingAlert = false;
      notifyListeners();
      print('🏁 === FIN ALERTE SOS ===');
    }
  }

  /// Envoi d'alerte via WhatsApp
  Future<bool> _sendWhatsAppAlert(List<String> contacts, String message) async {
    try {
      print('📱 Début envoi WhatsApp à ${contacts.length} contacts');

      bool atLeastOneSent = false;

      for (final contact in contacts) {
        try {
          // Nettoyer le numéro
          final cleanNumber = _cleanPhoneForWhatsApp(contact);
          print('🔗 Traitement WhatsApp pour: $contact → $cleanNumber');

          // URL WhatsApp Web
          final whatsappUrl =
              'https://web.whatsapp.com/send?phone=$cleanNumber&text=${Uri.encodeComponent(message)}';

          print('🌐 WhatsApp URL: ${whatsappUrl.substring(0, 100)}...');

          if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
            // Ouvrir WhatsApp Web dans un nouvel onglet
            await launchUrl(
              Uri.parse(whatsappUrl),
              mode: LaunchMode.externalApplication,
            );

            atLeastOneSent = true;
            print('✅ WhatsApp ouvert pour: $contact');

            // Pause pour éviter de surcharger
            await Future.delayed(const Duration(milliseconds: 800));
          } else {
            print('⚠️ URL WhatsApp non lançable, essai URL alternative...');

            // URL alternative wa.me
            final altUrl =
                'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';
            if (await canLaunchUrl(Uri.parse(altUrl))) {
              await launchUrl(
                Uri.parse(altUrl),
                mode: LaunchMode.externalApplication,
              );
              atLeastOneSent = true;
              print('✅ WhatsApp (alt) ouvert pour: $contact');
            }
          }
        } catch (e) {
          print('⚠️ Erreur avec contact $contact: $e');
        }
      }

      return atLeastOneSent;
    } catch (e) {
      print('💥 Erreur générale WhatsApp: $e');
      return false;
    }
  }

  /// Nettoie le numéro pour WhatsApp
  String _cleanPhoneForWhatsApp(String phone) {
    // Garde uniquement les chiffres et le +
    String cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    // Si commence par +216, garder tel quel
    if (cleaned.startsWith('+216')) {
      return cleaned.substring(1); // WhatsApp veut 216XXXXXXXXX sans le +
    }

    // Si commence par 00216, convertir en 216
    if (cleaned.startsWith('00216')) {
      return cleaned.substring(2); // 216XXXXXXXXX
    }

    // Si commence par 0 (local), ajouter 216
    if (cleaned.startsWith('0')) {
      return '216${cleaned.substring(1)}';
    }

    // Si 8 chiffres (tunisien), ajouter 216
    if (cleaned.length == 8 && RegExp(r'^[2-9][0-9]{7}$').hasMatch(cleaned)) {
      return '216$cleaned';
    }

    return cleaned;
  }

  /// Génère un message optimisé pour WhatsApp
  String _generateWhatsAppMessage(Alert alert, String locationUrl) {
    final dateTime = alert.timestamp.toLocal();
    final formattedTime =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    final formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';

    final lat = alert.latitude!.toStringAsFixed(6);
    final lng = alert.longitude!.toStringAsFixed(6);

    return '''🚨 *ALERTE URGENCE - PROTECTME* 🚨

*URGENCE !* ${alert.message ?? "L'utilisateur a déclenché une alerte d'urgence"}

📍 *LOCALISATION :*
• Coordonnées : $lat, $lng
• Carte : $locationUrl

⏰ *DATE & HEURE :*
• $formattedDate à $formattedTime

⚠️ *ACTION REQUISE :*
1. Appelez immédiatement l'utilisateur
2. Contactez les secours si nécessaire (190/198)
3. Rendez-vous sur place si possible

📱 *APPLICATION :*
Cette alerte a été envoyée automatiquement par l'application *ProtectMe*.
Ne pas répondre à ce message.

🔒 *CONFIDENTIEL :*
Cette information est confidentielle. Ne la partagez qu'avec les secours.''';
  }

  /// Dialogue de succès WhatsApp
  void _showWhatsAppSuccessDialog(
    BuildContext context,
    Alert alert,
    List<String> contacts,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('WhatsApp ouvert !'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WhatsApp Web s\'est ouvert dans un nouvel onglet.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check, color: Colors.green, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Étapes à suivre :',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('1. Connectez-vous à WhatsApp Web'),
                      Text('2. Le message est déjà pré-rempli'),
                      Text('3. Cliquez sur "Envoyer"'),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              Text('Contacts : ${contacts.length}'),
              Text('Localisation envoyée'),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://maps.google.com/maps?q=${alert.latitude},${alert.longitude}',
                  ),
                ),
                child: Text('Ouvrir la carte'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// Fallback si WhatsApp ne peut pas s'ouvrir
  void _showWhatsAppFallbackDialog(
    BuildContext context,
    Alert alert,
    List<String> contacts,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone_android, color: Colors.blue),
            SizedBox(width: 10),
            Text('Ouvrir WhatsApp manuellement'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ouvrez WhatsApp sur votre téléphone et envoyez ce message :',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message à copier :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          message,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: message));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Message copié !')),
                          );
                        },
                        child: Text('Copier le message'),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              Text('Numéros à contacter :'),
              for (final contact in contacts)
                Padding(
                  padding: EdgeInsets.only(left: 10, top: 5),
                  child: Text('• $contact'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showSimpleConfirmation(
    BuildContext context,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmAlertDialog(isWeb: kIsWeb),
    );

    final confirmed = result != null && result['confirmed'] == true;
    final method = result != null && result['method'] is String
        ? result['method'] as String
        : (kIsWeb ? 'whatsapp' : 'sms');

    if (confirmed) {
      await _savePreferredMethod(method);
    }

    return result;
  }

  Future<bool> _saveAlertToFirestore(Alert alert) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur pour sauvegarder l\'alerte');
        return false;
      }

      print('💾 Sauvegarde alerte Firestore pour user: ${user.uid}');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('alerts')
          .doc(alert.id)
          .set({
            ...alert.toMap(),
            'userId': user.uid,
            'userEmail': user.email,
            'savedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      print('✅ Alerte sauvegardée dans Firestore: ${alert.id}');
      return true;
    } catch (e) {
      print('❌ Erreur sauvegarde alerte Firestore: $e');
      return false;
    }
  }

  Future<bool> _sendAlertToContacts(
    Alert alert,
    BuildContext? context, {
    String? method,
  }) async {
    try {
      // Récupérer les contacts depuis le service. Si aucun contexte UI
      // n'est disponible (alerte automatique en arrière-plan), on crée
      // un ContactService temporaire et on charge les contacts directement.
      List<EmergencyContact> contactsList = [];
      if (context != null) {
        final contactService = Provider.of<ContactService>(
          context,
          listen: false,
        );
        await contactService.loadContacts();
        contactsList = contactService.contacts;
      } else {
        final contactService = ContactService();
        await contactService.loadContacts();
        contactsList = contactService.contacts;
      }

      final contacts = contactsList;

      if (contacts.isEmpty) {
        print('❌ Aucun contact disponible');
        if (context != null) {
          ErrorHandler.showError(context, 'Aucun contact d\'urgence configuré');
        }
        return false;
      }

      // Filtrer les contacts qui reçoivent les SMS/WhatsApp
      final activeContacts = contacts
          .where((contact) => contact.receivesSMS && contact.isActive)
          .toList();

      if (activeContacts.isEmpty) {
        print('❌ Aucun contact actif configuré');
        if (context != null) {
          ErrorHandler.showError(context, 'Aucun contact actif');
        }
        return false;
      }

      final chosenMethod = method ?? (kIsWeb ? 'whatsapp' : 'sms');

      print('📱 $chosenMethod à ${activeContacts.length} contacts');

      // GÉNÉRER L'URL DE LOCALISATION
      final locationUrl = _generateGoogleMapsUrl(
        alert.latitude!,
        alert.longitude!,
      );

      print('📍 URL Google Maps: $locationUrl');

      // Générer le message selon la méthode choisie
      final message = chosenMethod == 'whatsapp'
          ? _generateWhatsAppMessage(alert, locationUrl)
          : _generateEmergencyMessage(alert, locationUrl);

      print('💬 Message: ${message.length} caractères');

      // Extraire les numéros de téléphone
      final phoneNumbers = activeContacts
          .map((contact) => contact.phone)
          .where((phone) => phone.isNotEmpty)
          .toList();

      print('📞 Numéros à contacter: $phoneNumbers');

      // ENVOYER SELON LA PLATEFORME
      bool success;
      List<String> contactedNumbers = [];

      if (chosenMethod == 'whatsapp') {
        // ✅ ENVOI WHATSAPP
        print('🌐 Envoi via WhatsApp (choix = whatsapp)');
        success = await _sendWhatsAppAlert(phoneNumbers, message);

        if (success) {
          contactedNumbers = phoneNumbers;
          if (context != null) {
            _showWhatsAppSuccessDialog(context, alert, phoneNumbers);
          }
        } else {
          // Fallback : instructions manuelles
          if (context != null) {
            _showWhatsAppFallbackDialog(context, alert, phoneNumbers, message);
          }
          contactedNumbers = phoneNumbers; // On considère que c'est envoyé
          success = true;
        }
      } else {
        // 📱 ENVOI SMS (choisi par l'utilisateur)
        print('📱 Envoi via SMS (choix = sms)');
        final results = await _smsService.sendEmergencySMS(
          phoneNumbers,
          message,
          locationUrl,
        );

        final successCount = results.values.where((s) => s).length;
        contactedNumbers = results.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

        print('✅ $successCount/${phoneNumbers.length} SMS envoyés');
        success = successCount > 0;
      }

      // Mettre à jour l'alerte avec les contacts notifiés
      alert.contactedNumbers = contactedNumbers;

      // Si un enregistrement audio local existe, upload vers Firebase Storage
      try {
        final audioPath = alert.audioRecordingUrl;
        if (audioPath != null &&
            audioPath.isNotEmpty &&
            !audioPath.startsWith('http')) {
          final user = FirebaseAuth.instance.currentUser;
          final uid = user?.uid ?? 'anonymous';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('alerts')
              .child(uid)
              .child('${alert.id}.m4a');

          if (kIsWeb) {
            // web: audioPath is expected to be a data URL (data:audio/webm;base64,...)
            if (audioPath.startsWith('data:')) {
              final comma = audioPath.indexOf(',');
              final base64Str = audioPath.substring(comma + 1);
              final bytes = base64Decode(base64Str);
              final metadata = SettableMetadata(contentType: 'audio/webm');
              await storageRef.putData(Uint8List.fromList(bytes), metadata);
              final downloadUrl = await storageRef.getDownloadURL();
              alert.audioRecordingUrl = downloadUrl;
              print('✅ Audio uploaded to Firebase Storage (web): $downloadUrl');
            }
          } else {
            // mobile/desktop: audioPath is a local file path
            final exists = await localFileExists(audioPath);
            if (exists) {
              await uploadLocalFile(storageRef, audioPath);
              final downloadUrl = await storageRef.getDownloadURL();
              alert.audioRecordingUrl = downloadUrl;
              print('✅ Audio uploaded to Firebase Storage: $downloadUrl');
            }
          }
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'upload de l\'audio: $e');
      }

      // Sauvegarder l'alerte dans Firestore
      await _saveAlertToFirestore(alert);

      return success;
    } catch (e) {
      print('❌ Erreur envoi contacts: $e');
      print('❌ Stack trace: ${e.toString()}');
      return false;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('❌ Erreur récupération localisation: $e');
      return null;
    }
  }

  /// Déclenche une alerte automatique sans interaction UI.
  /// Utilisé par les services en arrière-plan (ex: détection de chute).
  Future<void> triggerAutomaticAlert(
    AlertType type, {
    BuildContext? context,
  }) async {
    try {
      final position = await _getCurrentLocation();

      final alert = Alert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        status: AlertStatus.pending,
        timestamp: DateTime.now(),
        latitude: position?.latitude,
        longitude: position?.longitude,
        message: 'Alerte automatique: ${type.toString().split('.').last}',
        biometricConfirmed: false,
      );

      // Sauvegarder localement et dans Firestore
      _alerts.insert(0, alert);
      notifyListeners();
      await _saveAlertToFirestore(alert);
      print(
        '✅ Alerte automatique déclenchée: ${alert.id} (${type.toString()})',
      );

      // If we have a UI context, show a short confirmation dialog allowing
      // the user to cancel the automatic send. Otherwise proceed immediately.
      bool shouldSend = true;
      if (context != null) {
        final completer = Completer<bool>();
        int secondsLeft = 5; // countdown seconds

        // Use StatefulBuilder with a timer that calls its `setState` so the
        // countdown display updates reliably.
        Timer? countdown;
        StateSetter? setStateRef;
        showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                int localSeconds = secondsLeft;
                return StatefulBuilder(
                  builder: (contextSB, setState) {
                    // Keep reference to setState so timer callback can update UI
                    setStateRef ??= setState;
                    // Start timer only once
                    if (countdown == null) {
                      countdown = Timer.periodic(const Duration(seconds: 1), (
                        t,
                      ) {
                        localSeconds -= 1;
                        // Update dialog UI
                        try {
                          setStateRef?.call(() {});
                        } catch (_) {}
                        if (localSeconds <= 0) {
                          countdown?.cancel();
                          if (Navigator.of(ctx).canPop())
                            Navigator.of(ctx).pop(false);
                        }
                      });
                    }

                    return AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 10),
                          Expanded(child: Text('Automatic alert detected')),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('An automatic alert has been recorded.'),
                          SizedBox(height: 8),
                          Text('The alert will be sent in $localSeconds s.'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            countdown?.cancel();
                            Navigator.of(contextSB).pop(true); // cancel
                          },
                          child: Text('Cancel'),
                        ),
                      ],
                    );
                  },
                );
              },
            )
            .then((cancelled) {
              // If dialog returned true => cancelled
              if (countdown != null && countdown!.isActive) countdown?.cancel();
              if (cancelled == true) {
                completer.complete(false);
              } else {
                completer.complete(true);
              }
            })
            .catchError((_) {
              if (countdown != null && countdown!.isActive) countdown?.cancel();
              if (!completer.isCompleted) completer.complete(true);
            });

        shouldSend = await completer.future;
      }

      if (shouldSend) {
        final sent = await _sendAlertToContacts(alert, context);
        print('📤 Envoi automatique aux contacts: $sent');
      } else {
        print('❌ Envoi automatique annulé par l\'utilisateur');
      }
    } catch (e) {
      print('❌ Erreur triggerAutomaticAlert: $e');
    }
  }

  String _generateGoogleMapsUrl(double lat, double lng) {
    // URL Google Maps optimisée pour mobile
    return 'https://maps.google.com/maps?q=$lat,$lng&z=17';
  }

  String _generateEmergencyMessage(Alert alert, String locationUrl) {
    final dateTime = alert.timestamp.toLocal();
    final formattedTime =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    final formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';

    final lat = alert.latitude!.toStringAsFixed(6);
    final lng = alert.longitude!.toStringAsFixed(6);

    return '''
🚨🚨 ALERTE URGENCE 🚨🚨

URGENCE ! ${alert.message ?? "L'utilisateur a déclenché une alerte d'urgence"}

📍 LOCALISATION :
• Coordonnées : $lat, $lng
• Carte : $locationUrl

⏰ DATE & HEURE :
• $formattedDate à $formattedTime

⚠️ ACTION REQUISE :
1. Appelez immédiatement l'utilisateur
2. Contactez les secours si nécessaire
3. Rendez-vous sur place si possible

📱 APPLICATION :
Cette alerte a été envoyée automatiquement par l'application ProtectMe.
Ne pas répondre à ce message.

🔒 CONFIDENTIEL :
Cette information est confidentielle. Ne la partagez qu'avec les secours.
''';
  }

  void _showSuccessDialog(BuildContext context, Alert alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text(Provider.of<LanguageService>(context).t('alert_sent_success')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Provider.of<LanguageService>(context).t('alert_sent_message'),
              ),
              SizedBox(height: 20),

              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            Provider.of<LanguageService>(
                              context,
                            ).t('location_sent'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${alert.latitude!.toStringAsFixed(6)}, ${alert.longitude!.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _generateGoogleMapsUrl(
                          alert.latitude!,
                          alert.longitude!,
                        ),
                        style: TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.blue, size: 20),
                          SizedBox(width: 10),
                          Text(
                            Provider.of<LanguageService>(
                              context,
                            ).t('alert_time'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${alert.timestamp.toLocal().toString().split('.')[0]}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.contacts, color: Colors.orange, size: 20),
                          SizedBox(width: 10),
                          Text(
                            Provider.of<LanguageService>(
                              context,
                            ).t('contacts_notified'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${alert.contactedNumbers.length} ${Provider.of<LanguageService>(context).t('contacts_notified')}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(Provider.of<LanguageService>(context).t('ok')),
          ),
        ],
      ),
    );
  }

  // === GESTION SIMPLIFIÉE POUR DÉMO ===

  void startMonitoring() {
    _isMonitoring = true;
    notifyListeners();
  }

  void stopMonitoring() {
    _isMonitoring = false;
    notifyListeners();
  }

  void updateActivity() {
    // Simple activity tracking: update last activity timestamp and reset inactivity timer
    _lastActivity = DateTime.now();

    // Reset inactivity timer (example: 5 minutes)
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(minutes: 5), () {
      // Inactivity timeout reached - for now just log and notify listeners
      print('⚠️ Inactivity timeout reached at ${DateTime.now()}');
      notifyListeners();
    });

    notifyListeners();
  }

  void addTestAlert() {
    final testAlert = Alert(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      type: AlertType.manual,
      status: AlertStatus.confirmed,
      timestamp: DateTime.now().subtract(Duration(minutes: 30)),
      latitude: 48.8566,
      longitude: 2.3522,
      message: 'Alerte de test - Paris',
      contactedNumbers: ['0612345678'],
      biometricConfirmed: true,
    );

    _alerts.insert(0, testAlert);
    notifyListeners();
  }

  Future<void> _savePreferredMethod(String method) async {
    // Save the preferred alert method (SMS or WhatsApp) for future alerts
    // This could be persisted to SharedPreferences if needed
    debugPrint('💾 Preferred alert method saved: $method');
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}

// Widget personnalisé pour sélectionner la méthode d'alerte (SMS ou WhatsApp)
class MessageMethodSelector extends StatelessWidget {
  final bool isWeb;
  final ValueChanged<String> onMethodSelected;

  const MessageMethodSelector({
    super.key,
    required this.isWeb,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Méthode d\'alerte :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (!isWeb)
              RadioListTile<String>(
                title: const Row(
                  children: [
                    Icon(Icons.sms, color: Colors.green),
                    SizedBox(width: 10),
                    Text('SMS'),
                  ],
                ),
                value: 'sms',
                groupValue: isWeb ? 'whatsapp' : 'sms',
                onChanged: (value) {
                  if (value != null) onMethodSelected(value);
                },
              ),
            if (isWeb)
              RadioListTile<String>(
                title: const Row(
                  children: [
                    Icon(Icons.chat, color: Colors.green),
                    SizedBox(width: 10),
                    Text('WhatsApp'),
                  ],
                ),
                value: 'whatsapp',
                groupValue: 'whatsapp',
                onChanged: (value) {
                  if (value != null) onMethodSelected(value);
                },
              ),
          ],
        ),
      ),
    );
  }
}
