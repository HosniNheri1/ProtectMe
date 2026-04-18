import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/language_service.dart';
import 'package:protectme/services/user_service.dart';
import 'package:protectme/services/auto_alert_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _monitoringEnabled = true;

  bool _locationTrackingEnabled = true;
  bool _biometricRequired = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    // Load settings from local storage or cloud
    // For now, use defaults
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<LanguageService>(context).t('settings')),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView(
        children: [
          // Monitoring section removed per user request (not used)
          // In the build method, after the other sections
          _buildSectionHeader('Automatic alerts'),
          _buildSwitchTile(
            title: 'Fall detection',
            subtitle: 'Trigger an alert when a fall is detected',
            value: context.watch<AutoAlertService>().fallDetectionEnabled,
            onChanged: (value) {
              context.read<AutoAlertService>().updatePreferences(
                fallDetection: value,
              );
            },
          ),
          _buildSwitchTile(
            title: 'Inactivity detection',
            subtitle: 'Alert if no movement for a certain time',
            value: context.watch<AutoAlertService>().inactivityDetectionEnabled,
            onChanged: (value) {
              context.read<AutoAlertService>().updatePreferences(
                inactivityDetection: value,
              );
            },
          ),
          // Advanced inactivity details (day/night)
          if (context.watch<AutoAlertService>().inactivityDetectionEnabled) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Inactivity delays',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: const Text('Day period'),
              subtitle: Text(
                '${context.watch<AutoAlertService>().dayStartHour}h - ${context.watch<AutoAlertService>().dayEndHour}h',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showHourPickerDialog(context),
              ),
            ),
            ListTile(
              title: const Text('Delay (day)'),
              subtitle: Builder(
                builder: (ctx) {
                  final seconds = context
                      .watch<AutoAlertService>()
                      .inactivityTimeoutDaySeconds;
                  return Text(
                    seconds < 60 ? '$seconds s' : '${seconds ~/ 60} minutes',
                  );
                },
              ),
              trailing: DropdownButton<int>(
                value: context
                    .watch<AutoAlertService>()
                    .inactivityTimeoutDaySeconds,
                items: const [10, 60, 120, 300, 600].map((seconds) {
                  return DropdownMenuItem(
                    value: seconds,
                    child: Text(
                      seconds < 60 ? '$seconds s' : '${seconds ~/ 60} min',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    context.read<AutoAlertService>().updatePreferences(
                      inactivityTimeoutDay: value,
                    );
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Delay (night)'),
              subtitle: Builder(
                builder: (ctx) {
                  final seconds = context
                      .watch<AutoAlertService>()
                      .inactivityTimeoutNightSeconds;
                  return Text(
                    seconds < 60 ? '$seconds s' : '${seconds ~/ 60} minutes',
                  );
                },
              ),
              trailing: DropdownButton<int>(
                value: context
                    .watch<AutoAlertService>()
                    .inactivityTimeoutNightSeconds,
                items: const [10, 60, 120, 300, 600, 900].map((seconds) {
                  return DropdownMenuItem(
                    value: seconds,
                    child: Text(
                      seconds < 60 ? '$seconds s' : '${seconds ~/ 60} min',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    context.read<AutoAlertService>().updatePreferences(
                      inactivityTimeoutNight: value,
                    );
                  }
                },
              ),
            ),
          ],
          _buildSwitchTile(
            title: 'Network loss detection',
            subtitle: 'Alert if the network is disconnected for a certain time',
            value: context
                .watch<AutoAlertService>()
                .networkLossDetectionEnabled,
            onChanged: (value) {
              context.read<AutoAlertService>().updatePreferences(
                networkLossDetection: value,
              );
            },
          ),
          if (context.watch<AutoAlertService>().networkLossDetectionEnabled)
            ListTile(
              title: Text('Network loss delay'),
              subtitle: Text(
                '${context.watch<AutoAlertService>().networkLossTimeoutSeconds} seconds',
              ),
              trailing: DropdownButton<int>(
                value: context
                    .watch<AutoAlertService>()
                    .networkLossTimeoutSeconds,
                items: [5, 15, 30, 60, 120].map((seconds) {
                  return DropdownMenuItem(
                    value: seconds,
                    child: Text('$seconds s'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    context.read<AutoAlertService>().updatePreferences(
                      networkLossTimeout: value,
                    );
                  }
                },
              ),
            ),
          // Localized duplicate switches removed (use AutoAlertService toggles above)
          _buildSwitchTile(
            title: Provider.of<LanguageService>(context).t('location_tracking'),
            subtitle: Provider.of<LanguageService>(context).t('track_location'),
            value: _locationTrackingEnabled,
            onChanged: (value) async {
              setState(() => _locationTrackingEnabled = value);
              if (value) {
                await _requestLocationPermission();
              }
              _saveSettings();
            },
          ),

          const Divider(),

          _buildSectionHeader(
            Provider.of<LanguageService>(context).t('configuration'),
          ),
          ListTile(
            title: Text(
              Provider.of<LanguageService>(context).t('inactivity_timeout'),
            ),
            subtitle: Builder(
              builder: (ctx) {
                final seconds = context
                    .watch<AutoAlertService>()
                    .inactivityTimeoutDaySeconds;
                final minutes = seconds >= 60 ? (seconds ~/ 60) : null;
                return Text(
                  minutes != null
                      ? '$minutes ${Provider.of<LanguageService>(context).t('minutes')}'
                      : '$seconds s',
                );
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showInactivityTimeoutDialog,
          ),

          _buildSectionHeader(
            Provider.of<LanguageService>(context).t('security'),
          ),
          _buildSwitchTile(
            title: Provider.of<LanguageService>(context).t('biometric_auth'),
            subtitle: Provider.of<LanguageService>(context).t('require_auth'),
            value: _biometricRequired,
            onChanged: (value) => setState(() => _biometricRequired = value),
          ),

          ListTile(
            title: Text('Reset_Password'),
            trailing: const Icon(Icons.lock_reset),
            onTap: _onResetPassword,
          ),

          const Divider(),

          _buildSectionHeader(
            Provider.of<LanguageService>(context).t('notifications'),
          ),
          _buildSwitchTile(
            title: Provider.of<LanguageService>(context).t('notifications'),
            subtitle: Provider.of<LanguageService>(
              context,
            ).t('receive_notifications'),
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              if (value) {
                await _requestNotificationPermission();
              }
              _saveSettings();
            },
          ),

          const Divider(),

          _buildSectionHeader(
            Provider.of<LanguageService>(context).t('appearance'),
          ),
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return ListTile(
                title: Text(
                  Provider.of<LanguageService>(context).t('language'),
                ),
                subtitle: Text(languageService.currentLanguageName),
                trailing: const Icon(Icons.language),
                onTap: () => _showLanguageDialog(context),
              );
            },
          ),

          const Divider(),

          _buildSectionHeader(Provider.of<LanguageService>(context).t('about')),
          ListTile(
            title: Text(Provider.of<LanguageService>(context).t('app_version')),
            subtitle: const Text('1.0.0'),
            trailing: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: Text(Provider.of<LanguageService>(context).t('contact_us')),
            trailing: const Icon(Icons.help_outline),
            onTap: () => _showHelpDialog(context),
          ),
          ListTile(
            title: Text(Provider.of<LanguageService>(context).t('terms')),
            trailing: const Icon(Icons.description),
            onTap: () => _showTermsDialog(context),
          ),
          ListTile(
            title: Text(Provider.of<LanguageService>(context).t('more')),
            trailing: const Icon(Icons.cloud_sync),
            onTap: () => _syncWithCloud(),
          ),
        ],
      ),
    );
  }

  void _showHourPickerDialog(BuildContext context) {
    final autoService = context.read<AutoAlertService>();
    int tempStart = autoService.dayStartHour;
    int tempEnd = autoService.dayEndHour;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Day period'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Start: '),
                    DropdownButton<int>(
                      value: tempStart,
                      items: List.generate(24, (i) => i).map((h) {
                        return DropdownMenuItem(value: h, child: Text('$h h'));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => tempStart = value!);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('End: '),
                    DropdownButton<int>(
                      value: tempEnd,
                      items: List.generate(24, (i) => i).map((h) {
                        return DropdownMenuItem(value: h, child: Text('$h h'));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => tempEnd = value!);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  autoService.updatePreferences(
                    dayStartHour: tempStart,
                    dayEndHour: tempEnd,
                  );
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onResetPassword() async {
    final userService = context.read<UserService>();
    final messenger = ScaffoldMessenger.of(context);

    // Try to get current user's email
    final current = await userService.getCurrentUser();
    String? email = current?.email;

    if (email != null && email.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Reset_Password'),
          content: Text(
            'A password reset email will be sent to $email. Confirm?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Send'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    } else {
      // Ask user to enter an email
      final entered = await showDialog<String?>(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text('Enter email'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(hintText: 'email@example.com'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                child: Text('Send'),
              ),
            ],
          );
        },
      );
      if (entered == null || entered.isEmpty) return;
      email = entered;
    }

    // Send reset email
    final success = await userService.sendPasswordResetEmail(email);
    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Error sending reset email')),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  void _showInactivityTimeoutDialog() {
    // Initialize dialog value from AutoAlertService (in seconds -> minutes)
    final auto = context.read<AutoAlertService>();
    int currentSeconds = auto.inactivityTimeoutDaySeconds;
    int currentMinutes = currentSeconds >= 60 ? (currentSeconds ~/ 60) : 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Provider.of<LanguageService>(context).t('time')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Provider.of<LanguageService>(context).t('choose_timeout')),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: currentMinutes,
              items: [1, 5, 10, 15, 30, 60].map((minutes) {
                return DropdownMenuItem(
                  value: minutes,
                  child: Text(
                    '$minutes ${Provider.of<LanguageService>(context).t('minutes')}',
                  ),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  // Convert minutes -> seconds and persist for both day and night
                  final seconds = value * 60;
                  await context.read<AutoAlertService>().updatePreferences(
                    inactivityTimeoutDay: seconds,
                    inactivityTimeoutNight: seconds,
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Provider.of<LanguageService>(context).t('cancel')),
          ),
        ],
      ),
    );
  }

  // Note: `_requestPermissions` removed because the Monitoring section was deleted.

  Future<void> _requestLocationPermission() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  void _saveSettings() {
    // Save settings to local storage and sync to cloud
    // For now, just print
    debugPrint(
      'Settings saved: monitoring=$_monitoringEnabled, location=$_locationTrackingEnabled, notifications=$_notificationsEnabled',
    );
  }

  void _syncWithCloud() {
    // Sync settings with Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Provider.of<LanguageService>(context).t('sync_with_cloud'),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Provider.of<LanguageService>(context).t('help_support')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Provider.of<LanguageService>(context).t('help_bullet_1')),
            Text(Provider.of<LanguageService>(context).t('help_bullet_2')),
            Text(Provider.of<LanguageService>(context).t('help_bullet_3')),
            Text(Provider.of<LanguageService>(context).t('help_bullet_4')),
            Text(Provider.of<LanguageService>(context).t('help_bullet_5')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Provider.of<LanguageService>(context).t('close')),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Provider.of<LanguageService>(context).t('terms')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Provider.of<LanguageService>(context).t('terms_p1')),
              Text(Provider.of<LanguageService>(context).t('terms_p2')),
              Text(Provider.of<LanguageService>(context).t('terms_p3')),
              Text(Provider.of<LanguageService>(context).t('terms_p4')),
              Text(Provider.of<LanguageService>(context).t('terms_p5')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Provider.of<LanguageService>(context).t('close')),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Provider.of<LanguageService>(context).t('select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(Provider.of<LanguageService>(context).t('french')),
              onTap: () async {
                await context.read<LanguageService>().setLanguage('fr');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(Provider.of<LanguageService>(context).t('english')),
              onTap: () async {
                await context.read<LanguageService>().setLanguage('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(Provider.of<LanguageService>(context).t('arabic')),
              onTap: () async {
                await context.read<LanguageService>().setLanguage('ar');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
