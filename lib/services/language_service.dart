import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  late Locale _currentLocale;

  LanguageService() {
    _currentLocale = const Locale('en');
    _loadLanguage();
  }

  Locale get currentLocale => _currentLocale;

  String get currentLanguageCode => _currentLocale.languageCode;

  /// Human-friendly name for the currently selected language (displayed in UI).
  String get currentLanguageName {
    switch (currentLanguageCode) {
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }

  /// Locales supported by the application; used by MaterialApp.
  static List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);
    if (saved != null && saved.isNotEmpty) {
      _currentLocale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  // Instance helper used by widgets via Provider: Provider.of<LanguageService>(context).t('key')
  String t(String key) {
    return translate(key, currentLanguageCode);
  }

  // Static helper to translate a key for a given language code.
  static String translate(String key, String languageCode) {
    return _translations[languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  // Centralized translations map. Add keys here as needed.
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'home': 'Home',
      'profile': 'Profile',
      'contacts': 'Contacts',
      'alerts': 'Alerts',
      'consulter_reclamation': 'Consult complaints',
      'settings': 'Settings',
      'auth': 'Authentication',
      'login': 'Login',
      'signup': 'Sign up',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'firstname': 'First name',
      'lastname': 'Last name',
      'phone': 'Phone',
      'address': 'Address',
      'city': 'City',
      'country': 'Country',
      'emergency_number': 'Emergency number',

      'monitoring': 'Monitoring',
      'active_monitoring': 'Active Monitoring',
      'sos_button': 'SOS Button',
      'tap_sos': 'Tap SOS',

      'my_profile': 'My Profile',
      'edit_profile': 'Edit Profile',
      'save': 'Save',
      'cancel': 'Cancel',

      'account': 'Account',
      'privacy': 'Privacy',
      'notifications': 'Notifications',
      'appearance': 'Appearance',
      'language': 'Language',
      'french': 'Français',
      'english': 'English',
      'arabic': 'العربية',
      'select_language': 'Select Language',

      'ok': 'OK',
      'close': 'Close',
      'back': 'Back',

      // Settings / features
      'fall_detection': 'Fall Detection',
      'detect_falls': 'Automatically detect falls',
      'inactivity_detection': 'Inactivity Detection',
      'alert_inactivity': 'Alert if inactivity is prolonged',
      'location_tracking': 'Location Tracking',
      'track_location': 'Track location for alerts',
      'inactivity_timeout': 'Inactivity Timeout',
      'biometric_auth': 'Biometric Authentication',
      'require_auth': 'Require authentication for manual alerts',
      'receive_notifications': 'Receive alert notifications',
      'info': 'Information',
      'configuration': 'Configuration',
      'minutes': 'minutes',
      'security': 'Security',
      'app_version': 'App Version',
      'contact_us': 'Contact Us',
      'terms': 'Terms of Use',
      'more': 'More',
      'help_support': 'Help & Support',
      'help_bullet_1': '• The SOS button sends an immediate alert',
      'help_bullet_2': '• Monitoring auto-detects falls and inactivity',
      'help_bullet_3': '• Configure emergency contacts in Contacts',
      'help_bullet_4': '• Check alert history in Alerts tab',
      'help_bullet_5': '• Settings are synced with the cloud',
      'terms_p1': '1. This app is designed for personal safety.',
      'terms_p2': '2. Use only in real emergencies.',
      'terms_p3': '3. Location data is used only for alerts.',
      'terms_p4': '4. Respect the privacy of emergency contacts.',
      'terms_p5': '5. Data may be synced with the cloud for safety.',
      'choose_timeout': 'Choose timeout before inactivity alert:',
      'terms_of_use': 'Terms of Use',
      'change_photo': 'Change Photo',
      'receive_sms_alert': 'Receive SMS Alerts',
      'send_sms_urgency': 'Send SMS in case of emergency',
      'receive_call_alert': 'Receive Call Alerts',
      'call_urgency': 'Call in case of emergency',
      'send_alert': 'Send Alert',
      'sync_with_cloud': 'Sync with Cloud',
      'save_error': 'Error saving',
      'select_error': 'Please select at least one contact',
      // Test / SOS / Splash
      'test_sos_title': 'Test SOS',
      'add_test_alert': 'Add test alert',
      'status_label': 'Status:',
      'sending': 'Sending...',
      'ready': 'Ready',
      'alert_label': 'Alert',
      'app_name': 'ProtectMe',
      'tagline': 'your safety companion',
      'loading': 'Loading...',
      'impossible': 'Impossible',
      'add_contacts_first': 'Please add emergency contacts first',
      'sos_sent_title': 'SOS Sent',
      'sos_sent_message': 'Alert sent to {count} contact(s)',
      'sos_emergency_title': 'SOS Emergency',
      'emergency_contacts': 'Emergency Contacts',
      'loading_contacts': 'Loading contacts...',
      'retry': 'Retry',
      'no_emergency_contacts': 'No emergency contacts',
      'add_contacts': 'Add contacts',
      'contacts_configured': '{count} contact(s) configured',
      'sos': 'SOS',
      'hold_prompt': 'Hold... ({seconds}s)',
      'long_press': 'Long press',
      'sensor_status': 'Sensor Status',
      'sensors_active': 'Sensors: Active',
      'dashboard': 'Dashboard',
      'welcome_protectme': 'Welcome to ProtectMe',
      'relation': 'Relation:',
      'email_label': 'Email:',
      'call': 'Call',
      'send_sms': 'Send SMS',
      'priority_label': 'Priority',
      'activity_monitor': 'Activity Monitor',
      'monitoring_activity': 'Monitoring activity...',
      'i_am_safe': 'I am safe',
      'validate_biometric': 'Validate with biometrics',
      'cancel_alert': 'Cancel Alert',
      'security_confirmation': 'Security confirmation',
      'seconds': 'seconds',
      'confirm_sos': 'Confirm SOS Alert',
      'confirm_sos_message':
          'Do you really want to trigger an emergency alert?',
      'contacts_receive_sms_position':
          'Your contacts will receive an SMS with your location',
      'alert_sent_success': 'Alert sent successfully',
      'alert_sent_message':
          'Your SOS alert was sent to your emergency contacts.',
      'location_sent': 'Location sent:',
      'alert_time': 'Alert time:',
      'contacts_notified': 'Notified contacts:',
      'delete_account': 'Delete Account',
      'confirm_delete':
          'Are you sure you want to delete your account? This action cannot be undone.',
      'account_deleted': 'Account deleted successfully',
      'delete': 'Delete',
      'manage_users': 'Manage Users',
      'manage_roles': 'Manage Roles',
      'admin': 'Admin',
      'personal_info': 'Personal Information',
      'logout': 'Logout',
      'confirm_logout': 'Are you sure you want to log out?',
      'no_user_logged': 'No user logged in',

      // Confirm alert dialog / recording
      'send_method': 'Send method',
      'whatsapp': 'WhatsApp',
      'recommended_on_web': 'Sends a Message to your emergency contacts',
      'whatsapp_web_note': 'On web, WhatsApp will open in a new tab',
      'send_sms_note': 'Sends an SMS to your emergency contacts',
      'attach_audio': 'Attach an audio recording',
      'record': 'Record',
      'stop': 'Stop',
      'permission_micro_required': 'Microphone permission required',
      'recording_ready': 'Recording ready',
    },

    'fr': {
      'home': 'Accueil',
      'profile': 'Profil',
      'contacts': 'Contacts',
      'alerts': 'Alertes',
      'consulter_reclamation': 'Consulter réclamation',
      'settings': 'Paramètres',
      'auth': 'Authentification',
      'login': 'Connexion',
      'signup': 'Inscription',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'firstname': 'Prénom',
      'lastname': 'Nom',
      'phone': 'Téléphone',
      'address': 'Adresse',
      'city': 'Ville',
      'country': 'Pays',
      'emergency_number': 'Numéro d\'urgence',

      'monitoring': 'Surveillance',
      'active_monitoring': 'Surveillance active',
      'sos_button': 'Bouton SOS',
      'tap_sos': 'Appuyez sur SOS',

      'my_profile': 'Mon profil',
      'edit_profile': 'Modifier le profil',
      'save': 'Enregistrer',
      'cancel': 'Annuler',

      'account': 'Compte',
      'privacy': 'Confidentialité',
      'notifications': 'Notifications',
      'appearance': 'Apparence',
      'language': 'Langue',
      'french': 'Français',
      'english': 'English',
      'arabic': 'العربية',
      'select_language': 'Choisir la langue',

      'ok': 'OK',
      'close': 'Fermer',
      'back': 'Retour',

      'fall_detection': 'Détection de chute',
      'detect_falls': 'Détecter automatiquement les chutes',
      'inactivity_detection': 'Détection d\'inactivité',
      'alert_inactivity': 'Alerte en cas d\'inactivité prolongée',
      'location_tracking': 'Suivi de localisation',
      'track_location': 'Suivre la position pour les alertes',
      'inactivity_timeout': 'Délai d\'inactivité',
      'biometric_auth': 'Authentification biométrique',
      'require_auth': 'Exiger l\'authentification pour les alertes manuelles',
      'receive_notifications': 'Recevoir les notifications d\'alerte',
      'info': 'Information',
      'configuration': 'Configuration',
      'minutes': 'minutes',
      'security': 'Sécurité',
      'app_version': 'Version de l\'application',
      'contact_us': 'Contactez-nous',
      'terms': 'Conditions d\'utilisation',
      'more': 'Plus',
      'help_support': 'Aide & Support',
      'help_bullet_1': '• Le bouton SOS envoie une alerte immédiate',
      'help_bullet_2':
          '• La surveillance détecte automatiquement les chutes et l\'inactivité',
      'help_bullet_3':
          '• Configurez vos contacts d\'urgence dans l\'onglet Contacts',
      'help_bullet_4':
          '• Vérifiez l\'historique des alertes dans l\'onglet Alertes',
      'help_bullet_5': '• Les paramètres sont synchronisés avec le cloud',
      'terms_p1':
          '1. Cette application est conçue pour la sécurité personnelle.',
      'terms_p2': '2. Utilisez uniquement en cas d\'urgence réelle.',
      'terms_p3':
          '3. Les données de localisation sont utilisées uniquement pour les alertes.',
      'terms_p4': '4. Respectez la vie privée des contacts d\'urgence.',
      'terms_p5':
          '5. Les données peuvent être synchronisées avec le cloud pour la sécurité.',
      'choose_timeout': 'Choisir le délai avant l\'alerte d\'inactivité :',
      'terms_of_use': 'Conditions d\'utilisation',
      'change_photo': 'Changer la photo',
      'receive_sms_alert': 'Recevoir les SMS d\'alerte',
      'send_sms_urgency': 'Envoyer un SMS en cas d\'urgence',
      'receive_call_alert': 'Recevoir les appels d\'alerte',
      'call_urgency': 'Appeler en cas d\'urgence',
      'send_alert': 'Envoyer l\'alerte',
      'sync_with_cloud': 'Synchroniser avec le cloud',
      'save_error': 'Erreur lors de la sauvegarde',
      'select_error': 'Veuillez sélectionner au moins un contact',
      // Test / SOS / Splash
      'test_sos_title': 'Test SOS',
      'add_test_alert': 'Ajouter alerte test',
      'status_label': 'Statut :',
      'sending': 'Envoi...',
      'ready': 'Prêt',
      'alert_label': 'Alerte',
      'app_name': 'ProtectMe',
      'tagline': 'votre compagnon de sécurité',
      'loading': 'Chargement...',
      'impossible': 'Impossible',
      'add_contacts_first': 'Ajoutez d\'abord des contacts d\'urgence',
      'sos_sent_title': 'SOS Envoyé',
      'sos_sent_message': 'Alerte envoyée à {count} contact(s)',
      'sos_emergency_title': 'SOS Urgence',
      'emergency_contacts': 'Contacts d\'urgence',
      'loading_contacts': 'Chargement des contacts...',
      'retry': 'Réessayer',
      'no_emergency_contacts': 'Aucun contact d\'urgence',
      'add_contacts': 'Ajouter des contacts',
      'contacts_configured': '{count} contact(s) configuré(s)',
      'sos': 'SOS',
      'hold_prompt': 'Maintenez... ({seconds}s)',
      'long_press': 'Appuyez longuement',
      'sensor_status': 'État des capteurs',
      'sensors_active': 'Capteurs : actifs',
      'dashboard': 'Tableau de bord',
      'welcome_protectme': 'Bienvenue sur ProtectMe',
      'relation': 'Relation :',
      'email_label': 'E-mail :',
      'call': 'Appeler',
      'send_sms': 'Envoyer SMS',
      'priority_label': 'Priorité',
      'activity_monitor': 'Moniteur d\'activité',
      'monitoring_activity': 'Surveillance en cours...',
      'i_am_safe': 'Je suis en sécurité',
      'validate_biometric': 'Valider par biométrie',
      'cancel_alert': 'Annuler l\'alerte',
      'security_confirmation': 'Confirmation de sécurité',
      'seconds': 'secondes',
      'confirm_sos': 'Confirmer alerte SOS',
      'confirm_sos_message':
          'Voulez-vous vraiment déclencher une alerte d\'urgence?',
      'contacts_receive_sms_position':
          'Vos contacts recevront un SMS avec votre position',
      'alert_sent_success': 'Alerte envoyée avec succès',
      'alert_sent_message':
          'Votre alerte SOS a été envoyée à vos contacts d\'urgence.',
      'location_sent': 'Localisation envoyée :',
      'alert_time': 'Heure de l\'alerte :',
      'contacts_notified': 'Contacts notifiés :',
      'delete_account': 'Supprimer le compte',
      'confirm_delete':
          'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action ne peut pas être annulée.',
      'account_deleted': 'Compte supprimé avec succès',
      'delete': 'Supprimer',
      'manage_users': 'Gérer les utilisateurs',
      'manage_roles': 'Gérer les rôles',
      'admin': 'Admin',
      'personal_info': 'Informations personnelles',
      'logout': 'Se déconnecter',
      'confirm_logout': 'Êtes-vous sûr de vouloir vous déconnecter ?',
      'no_user_logged': 'Aucun utilisateur connecté',
      // Confirm alert dialog / recording
      'send_method': 'Méthode d\'envoi',
      'whatsapp': 'WhatsApp',
      'recommended_on_web': 'Envoie un message à vos contacts d\'urgence',
      'whatsapp_web_note': 'Sur web, WhatsApp s\'ouvrira dans un nouvel onglet',
      'send_sms_note': 'Envoie un SMS à vos contacts d\'urgence',
      'attach_audio': 'Joindre un enregistrement audio',
      'record': 'Enregistrer',
      'stop': 'Stop',
      'permission_micro_required': 'Permission micro requise',
      'recording_ready': 'Enregistrement prêt',
    },

    'ar': {
      'home': 'الرئيسية',
      'profile': 'الملف الشخصي',
      'contacts': 'جهات الاتصال',
      'alerts': 'التنبيهات',
      'consulter_reclamation': 'عرض الشكوى',
      'settings': 'الإعدادات',
      'auth': 'المصادقة',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'firstname': 'الاسم الأول',
      'lastname': 'اسم العائلة',
      'phone': 'الهاتف',
      'address': 'العنوان',
      'city': 'المدينة',
      'country': 'الدولة',
      'emergency_number': 'رقم الطوارئ',

      'monitoring': 'المراقبة',
      'active_monitoring': 'المراقبة النشطة',
      'sos_button': 'زر الطوارئ',
      'tap_sos': 'اضغط على الطوارئ',

      'my_profile': 'ملفي الشخصي',
      'edit_profile': 'تعديل الملف الشخصي',
      'save': 'حفظ',
      'cancel': 'إلغاء',

      'account': 'الحساب',
      'privacy': 'الخصوصية',
      'notifications': 'الإشعارات',
      'appearance': 'المظهر',
      'language': 'اللغة',
      'french': 'Français',
      'english': 'English',
      'arabic': 'العربية',
      'select_language': 'اختر اللغة',

      'ok': 'حسناً',
      'close': 'إغلاق',
      'back': 'رجوع',

      'fall_detection': 'كشف السقوط',
      'detect_falls': 'كشف السقوط تلقائياً',
      'inactivity_detection': 'اكتشاف عدم النشاط',
      'alert_inactivity': 'تنبيه في حالة عدم النشاط المطول',
      'location_tracking': 'تتبع الموقع',
      'track_location': 'تتبع الموقع من أجل التنبيهات',
      'inactivity_timeout': 'مهلة عدم النشاط',
      'biometric_auth': 'المصادقة البيومترية',
      'require_auth': 'طلب المصادقة للتنبيهات اليدوية',
      'receive_notifications': 'استقبال إشعارات التنبيه',
      'info': 'معلومات',
      'configuration': 'التكوين',
      'minutes': 'دقائق',
      'security': 'الأمان',
      'app_version': 'إصدار التطبيق',
      'contact_us': 'اتصل بنا',
      'terms': 'شروط الاستخدام',
      'more': 'المزيد',
      'help_support': 'المساعدة والدعم',
      'help_bullet_1': '• زر الطوارئ يرسل تنبيهًا فوريًا',
      'help_bullet_2': '• المراقبة تكتشف السقوط وعدم النشاط تلقائيًا',
      'help_bullet_3': '• قم بتكوين جهات اتصال الطوارئ في جهات الاتصال',
      'help_bullet_4': '• تحقق من سجل التنبيهات في تبويب التنبيهات',
      'help_bullet_5': '• تتم مزامنة الإعدادات مع السحابة',
      'terms_p1': '1. تم تصميم هذا التطبيق للسلامة الشخصية.',
      'terms_p2': '2. استخدمه فقط في حالات الطوارئ الحقيقية.',
      'terms_p3': '3. تُستخدم بيانات الموقع فقط من أجل التنبيهات.',
      'terms_p4': '4. احترم خصوصية جهات الاتصال الطارئة.',
      'terms_p5': '5. قد يتم مزامنة البيانات مع السحابة من أجل الأمان.',
      'choose_timeout': 'اختر المهلة قبل تنبيه عدم النشاط:',
      'terms_of_use': 'شروط الاستخدام',
      'change_photo': 'تغيير الصورة',
      'receive_sms_alert': 'استقبال تنبيهات SMS',
      'send_sms_urgency': 'إرسال رسالة نصية في حالة الطوارئ',
      'receive_call_alert': 'استقبال تنبيهات الاتصال',
      'call_urgency': 'الاتصال في حالة الطوارئ',
      'send_alert': 'إرسال التنبيه',
      'sync_with_cloud': 'المزامنة مع السحابة',
      'save_error': 'خطأ في الحفظ',
      'select_error': 'يرجى تحديد جهة اتصال واحدة على الأقل',
      // Test / SOS / Splash
      'test_sos_title': 'اختبار SOS',
      'add_test_alert': 'إضافة تنبيه اختبار',
      'status_label': 'الحالة :',
      'sending': 'جارٍ الإرسال...',
      'ready': 'جاهز',
      'alert_label': 'تنبيه',
      'app_name': 'ProtectMe',
      'tagline': 'رفيق الأمان الخاص بك',
      'loading': 'جارٍ التحميل...',
      'impossible': 'غير ممكن',
      'add_contacts_first': 'يرجى إضافة جهات الاتصال الطارئة أولاً',
      'sos_sent_title': 'تم إرسال SOS',
      'sos_sent_message': 'تم إرسال التنبيه إلى {count} جهة اتصال',
      'sos_emergency_title': 'طوارئ SOS',
      'emergency_contacts': 'جهات الاتصال الطارئة',
      'loading_contacts': 'جارٍ تحميل جهات الاتصال...',
      'retry': 'أعد المحاولة',
      'no_emergency_contacts': 'لا توجد جهات اتصال طارئة',
      'add_contacts': 'إضافة جهات الاتصال',
      'contacts_configured': '{count} جهة اتصال مُعدة',
      'sos': 'SOS',
      'hold_prompt': 'استمر بالضغط... ({seconds}s)',
      'long_press': 'اضغط مطولاً',
      'sensor_status': 'حالة المستشعر',
      'sensors_active': 'المستشعرات: نشطة',
      'dashboard': 'لوحة التحكم',
      'welcome_protectme': 'مرحبًا بك في ProtectMe',
      'relation': 'العلاقة :',
      'email_label': 'البريد الإلكتروني :',
      'call': 'اتصال',
      'send_sms': 'إرسال رسالة',
      'priority_label': 'الأولوية',
      'activity_monitor': 'مراقبة النشاط',
      'monitoring_activity': 'جارٍ مراقبة النشاط...',
      'i_am_safe': 'أنا بأمان',
      'validate_biometric': 'التحقق بواسطة القياسات الحيوية',
      'cancel_alert': 'إلغاء التنبيه',
      'security_confirmation': 'تأكيد الأمان',
      'seconds': 'ثانية',
      'confirm_sos': 'تأكيد تنبيه الطوارئ',
      'confirm_sos_message': 'هل تريد حقًا إطلاق تنبيه الطوارئ؟',
      'contacts_receive_sms_position':
          'سيتلقى جهات الاتصال الخاصة بك رسالة قصيرة تحتوي على موقعك',
      'alert_sent_success': 'تم إرسال التنبيه بنجاح',
      'alert_sent_message':
          'تم إرسال تنبيه SOS الخاص بك إلى جهات اتصال الطوارئ.',
      'location_sent': 'الموقع المرسل:',
      'alert_time': 'وقت التنبيه:',
      'contacts_notified': 'الجهات التي تم إخطارها:',
      'delete_account': 'حذف الحساب',
      'confirm_delete':
          'هل أنت متأكد من رغبتك في حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.',
      'account_deleted': 'تم حذف الحساب بنجاح',
      'delete': 'حذف',
      'manage_users': 'إدارة المستخدمين',
      'manage_roles': 'إدارة الأدوار',
      'admin': 'Admin',
      'personal_info': 'معلومات شخصية',
      'logout': 'تسجيل الخروج',
      'confirm_logout': 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
      'no_user_logged': 'لا يوجد مستخدم مسجل دخول',
      // Confirm alert dialog / recording
      'send_method': 'طريقة الإرسال',
      'whatsapp': 'واتساب',
      'recommended_on_web':
          'يرسل رسالة إلى جهات الاتصال الخاصة بك في حالات الطوارئ',
      'whatsapp_web_note': 'على الويب، سيفتح واتساب في علامة تبويب جديدة',
      'send_sms_note': 'يرسل رسالة نصية إلى جهات اتصال الطوارئ الخاصة بك',
      'attach_audio': 'إرفاق تسجيل صوتي',
      'record': 'تسجيل',
      'stop': 'إيقاف',
      'permission_micro_required': 'مطلوب إذن الميكروفون',
      'recording_ready': 'التسجيل جاهز',
    },
  };
}
