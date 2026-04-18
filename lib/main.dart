import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:protectme/screens/home/home_screen.dart';
import 'package:protectme/screens/profile/profile_screen.dart';
import 'package:protectme/screens/contacts/contacts_screen.dart';
import 'package:protectme/screens/alerts/alerts_screen.dart';
import 'package:protectme/screens/settings/settings_screen.dart';
import 'package:protectme/screens/authentication/authentication_screen.dart';
import 'package:protectme/services/alert_service.dart';
import 'package:protectme/services/location_service.dart';
import 'package:protectme/services/auth_service.dart';
import 'package:protectme/services/contact_service.dart';
import 'package:protectme/services/user_service.dart';
import 'package:protectme/services/complaint_service.dart';
import 'package:protectme/screens/admin/complaints_admin_screen.dart';
import 'package:protectme/widgets/admin_gate.dart';
import 'package:protectme/screens/admin/user_roles_screen.dart';
import 'package:protectme/screens/reclamation/my_complaints_screen.dart';
import 'package:protectme/services/language_service.dart';
import 'package:protectme/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated automatically
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'splash_page.dart';
import 'package:protectme/utils/app_navigator.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:protectme/services/auto_alert_service.dart';
import 'package:protectme/services/fall_detection_service.dart';
import 'package:protectme/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // If running locally (localhost) use the Firebase Storage emulator
    try {
      final host = Uri.base.host;
      final isLocalhost = host == 'localhost' || host == '127.0.0.1';
      if (isLocalhost) {
        // Use numeric loopback to avoid hostname resolution mismatches
        const emulatorHost = '127.0.0.1';
        const emulatorPort = 9199;
        FirebaseStorage.instance.useStorageEmulator(emulatorHost, emulatorPort);
        print(
          '⚙️ Firebase Storage configured to use emulator at $emulatorHost:$emulatorPort',
        );
      }
    } catch (e) {
      print('⚠️ Could not configure Firebase Storage emulator: $e');
    }
    print('✅ Firebase initialized successfully');
    // Debug: print Firebase config and current auth user for diagnostics
    _debugFirebaseConfig();
    // Wait a bit to ensure Firebase is actually ready
    await Future.delayed(const Duration(milliseconds: 800));
  } catch (e) {
    print('❌ Erreur Firebase init: $e');
  }

  runApp(const MyApp());
}

void _debugFirebaseConfig() {
  try {
    print(
      '🔍 Firebase debug: projectId=${DefaultFirebaseOptions.currentPlatform.projectId}',
    );
    print('🔍 Firebase debug: appName=${Firebase.app().name}');
    final user = fb.FirebaseAuth.instance.currentUser;
    print(
      '🔍 Firebase debug: auth.currentUser=${user != null ? user.uid + " (" + (user.email ?? '') + ")" : 'null'}',
    );
  } catch (e) {
    print('🔍 Firebase debug error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect if running on Web and print a warning
    if (kIsWeb) {
      print('⚠️ APPLICATION RUNNING ON WEB - SMS LIMITED');
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AlertService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => ContactService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => FallDetectionService()),
        Provider(create: (_) => UserService()),
        Provider(create: (_) => ComplaintService()),
        // ChangeNotifierProvider(create: (_) => SensorService()),
        Provider(create: (_) => NotificationService()),
        ChangeNotifierProvider(
          create: (context) => AutoAlertService(
            context.read<FallDetectionService>(),
            context.read<AlertService>(),
            context.read<NotificationService>(),
          ),
        ),
      ],
      child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'ProtectMe',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            locale: languageService.currentLocale,
            supportedLocales: LanguageService.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SplashPage(),
            routes: {
              '/home': (context) => HomeScreen(),
              '/profile': (context) => ProfileScreen(),
              '/admin/complaints': (context) =>
                  AdminGate(child: ComplaintsAdminScreen()),
              '/admin/users': (context) => AdminGate(child: UserRolesScreen()),
              '/contacts': (context) => ContactsScreen(),
              '/alerts': (context) => AlertsScreen(),
              '/settings': (context) => SettingsScreen(),
              '/complaints': (context) => MyComplaintsScreen(),
              '/auth': (context) => AuthenticationScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  AuthWrapperState createState() => AuthWrapperState();
}

class AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    // Check authentication status when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final authService = context.read<AuthService>();
    await authService.checkAuthStatus();
    setState(() => _isCheckingAuth = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated && authService.currentUser != null) {
          return HomeScreen();
        }
        return AuthenticationScreen();
      },
    );
  }
}
