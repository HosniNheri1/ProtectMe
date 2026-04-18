import 'package:flutter/material.dart';
import 'package:protectme/models/user.dart';
import 'package:protectme/models/firestore_user.dart';
import 'package:protectme/screens/profile/edit_profile_screen.dart';
import 'package:protectme/screens/reclamation/reclamation_screen.dart';
import 'package:protectme/screens/admin/complaints_admin_screen.dart';
import 'package:protectme/services/auth_service.dart';
import 'package:protectme/services/language_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:protectme/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  // Optional test user: when provided, the screen will use this user
  // instead of loading from UserService. Useful for widget tests.
  final dynamic testFirestoreUser;

  const ProfileScreen({super.key, this.testFirestoreUser});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  FirestoreUser? _firestoreUser;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userService = Provider.of<UserService>(context, listen: false);
    if (widget.testFirestoreUser != null) {
      setState(() {
        _firestoreUser = widget.testFirestoreUser;
        _isLoading = false;
      });
      return;
    }

    final user = await userService.getCurrentUser();

    setState(() {
      _firestoreUser = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_firestoreUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            Provider.of<LanguageService>(context).t('user_not_found'),
          ),
        ),
      );
    }

    final user = _firestoreUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            Provider.of<LanguageService>(context).t('no_user_logged'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<LanguageService>(context).t('my_profile')),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final updatedUser = await Navigator.push<User>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    user: User(
                      id: user.id,
                      name: user.name,
                      email: user.email,
                      birthDate: user.birthDate,
                    ),
                  ),
                ),
              );
              if (updatedUser != null) {
                try {
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  await authService.updateCurrentUser(updatedUser);
                  // Recharger les données depuis Firestore pour refléter
                  // immédiatement les changements (ex: photo locale ou URL)
                  await _loadUserData();
                } catch (_) {
                  // In tests there may be no AuthService; ignore.
                }
              }
            },
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
                try {
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  await authService.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/auth',
                    (r) => false,
                  );
                } catch (_) {
                  // No AuthService in tests.
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: user.photoUrl != null
                        ? (user.photoUrl!.startsWith('data:')
                              ? MemoryImage(
                                  base64Decode(user.photoUrl!.split(',').last),
                                )
                              : (user.photoUrl!.startsWith('http')
                                    ? NetworkImage(user.photoUrl!)
                                    : FileImage(File(user.photoUrl!))))
                        : null,
                    backgroundColor: Colors.grey.shade200,
                    child: user.photoUrl == null
                        ? Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  SizedBox(height: 16),
                  Text(
                    user.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(user.email, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Personal Information
            _buildSectionTitle(
              Provider.of<LanguageService>(context).t('personal_info'),
            ),
            _buildInfoCard(
              children: [
                _buildInfoRow(
                  Provider.of<LanguageService>(context).t('phone'),
                  user.phone ?? Provider.of<LanguageService>(context).t('info'),
                ),
                _buildInfoRow(
                  'Birth date',
                  '${user.birthDate.day}/${user.birthDate.month}/${user.birthDate.year}',
                ),
                _buildInfoRow('Blood type', user.bloodType ?? 'Not specified'),
              ],
            ),

            SizedBox(height: 24),

            // Medical Information
            _buildSectionTitle('Medical information'),
            _buildInfoCard(
              children: [
                _buildInfoRow(
                  'Medical information',
                  user.medicalInfo ?? 'Not specified',
                ),
                _buildInfoRow(
                  'Allergies',
                  user.allergies.isNotEmpty
                      ? user.allergies.join(', ')
                      : 'None',
                ),
              ],
            ),

            SizedBox(height: 32),

            // Danger Zone - Account Management
            _buildSectionTitle(
              Provider.of<LanguageService>(context).t('account'),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.report_problem),
              label: Text(
                _firestoreUser?.role == 'admin'
                    ? 'View complaints'
                    : 'Submit a complaint',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 44),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _firestoreUser?.role == 'admin'
                        ? const ComplaintsAdminScreen()
                        : const ReclamationScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.delete_forever),
              label: Text(
                Provider.of<LanguageService>(context).t('delete_account'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 44),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      Provider.of<LanguageService>(context).t('delete_account'),
                    ),
                    content: Text(
                      Provider.of<LanguageService>(context).t('confirm_delete'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          Provider.of<LanguageService>(context).t('cancel'),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          Provider.of<LanguageService>(context).t('delete'),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final success = await authService.deleteAccount();
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            Provider.of<LanguageService>(
                              context,
                            ).t('account_deleted'),
                          ),
                        ),
                      );
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/auth',
                        (r) => false,
                      );
                    }
                  } catch (_) {
                    // No AuthService in tests.
                  }
                }
              },
            ),
            SizedBox(height: 16),

            // Admin: manage users
            if (_firestoreUser?.role == 'admin')
              ElevatedButton.icon(
                key: Key('manageUsersButton'),
                icon: Icon(Icons.admin_panel_settings),
                label: Text(
                  Provider.of<LanguageService>(context).t('manage_users'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 44),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/admin/users');
                },
              ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(top: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(color: Colors.grey.shade900)),
          ),
        ],
      ),
    );
  }
}
