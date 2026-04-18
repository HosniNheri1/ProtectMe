import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/alert_service.dart';
import 'package:protectme/services/location_service.dart';
import 'package:protectme/services/notification_service.dart';
import 'package:protectme/services/auth_service.dart';
import 'package:protectme/services/language_service.dart';
import 'package:protectme/widgets/sos_button.dart';
import 'package:protectme/widgets/dashboard_widget.dart';
import 'package:protectme/widgets/activity_monitor.dart';
import 'package:protectme/widgets/app_drawer.dart';
import 'package:protectme/services/fall_detection_service.dart';
import 'package:protectme/services/auto_alert_service.dart';
import 'package:protectme/models/alert.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fallService = Provider.of<FallDetectionService>(
        context,
        listen: false,
      );
      await fallService.loadModel();
      fallService.onFallDetected = () {
        // Déclencher l'alerte automatique en passant le contexte pour afficher
        // la confirmation courte (5s) à l'utilisateur.
        context.read<AlertService>().triggerAutomaticAlert(
          AlertType.fall,
          context: context,
        );
      };
      fallService.startListening();
    });

    // Initialiser les autres services après le chargement UI
    _initializeServices();
  }

  void _initializeServices() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    // final sensorService = Provider.of<SensorService>(context, listen: false);
    final alertService = Provider.of<AlertService>(context, listen: false);
    final notificationService = NotificationService();

    await locationService.initialize();
    await notificationService.initialize();

    // Set callback for inactivity alerts
    // alertService.onInactivityAlert = _showInactivityConfirmation;

    // await sensorService.initialize();
    alertService.startMonitoring();
  }

  void startMonitoring() {
    print('AutoAlertService startMonitoring');
    // Delegate to the AutoAlertService public API instead of calling a
    // library-private method that isn't accessible from this file.
    Provider.of<AutoAlertService>(context, listen: false).startMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'ProtectMe',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: Provider.of<LanguageService>(context).t('logout'),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    Provider.of<LanguageService>(context).t('logout'),
                  ),
                  content: Text(
                    Provider.of<LanguageService>(context).t('confirm_logout'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        Provider.of<LanguageService>(context).t('cancel'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        Provider.of<LanguageService>(context).t('logout'),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // Call logout on AuthService and navigate to auth screen
                await Provider.of<AuthService>(context, listen: false).logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/auth',
                  (r) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // SOS Button
              SizedBox(height: 20),
              Consumer<AlertService>(
                builder: (context, alertService, child) {
                  return SOSButton(
                    onPressed: () => alertService.triggerManualAlert(context),
                    isActive: true,
                  );
                },
              ),

              SizedBox(height: 30),

              // Dashboard
              DashboardWidget(),

              SizedBox(height: 20),

              // Monitoring card removed per design

              // Activity Monitor
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ActivityMonitor(),
                ),
              ),

              SizedBox(height: 12),
              // Temporary test button to trigger a simulated fall (remove after tests)
              ElevatedButton.icon(
                onPressed: () {
                  try {
                    context.read<FallDetectionService>().triggerTestFall();
                  } catch (e) {
                    print('⚠️ triggerTestFall failed: $e');
                  }
                },
                icon: Icon(Icons.hardware),
                label: Text('Test fall'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 237, 8, 245),
                ),
              ),

              SizedBox(height: 20),

              // Quick Actions
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildQuickAction(
                    icon: Icons.contacts,
                    label: Provider.of<LanguageService>(context).t('contacts'),
                    onTap: () => Navigator.pushNamed(context, '/contacts'),
                  ),
                  _buildQuickAction(
                    icon: Icons.settings,
                    label: Provider.of<LanguageService>(context).t('settings'),
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  _buildQuickAction(
                    icon: Icons.history,
                    label: 'Alert_History',
                    onTap: () => Navigator.pushNamed(context, '/alerts'),
                  ),
                  _buildQuickAction(
                    icon: Icons.medical_services,
                    label: Provider.of<LanguageService>(context).t('info'),
                    onTap: () => _showMedicalInfo(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicalInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blood type: O+'),
            Text('Allergies: Penicillin, Pollen'),
            Text('Medications: None'),
            Text('Conditions: Mild asthma'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: Provider.of<LanguageService>(context).t('home'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.contacts),
          label: Provider.of<LanguageService>(context).t('contacts'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: Provider.of<LanguageService>(context).t('alerts'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: Provider.of<LanguageService>(context).t('settings'),
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            break; // Already on home
          case 1:
            Navigator.pushNamed(context, '/contacts');
            break;
          case 2:
            Navigator.pushNamed(context, '/alerts');
            break;
          case 3:
            Navigator.pushNamed(context, '/settings');
            break;
        }
      },
    );
  }
}
