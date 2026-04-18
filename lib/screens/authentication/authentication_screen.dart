import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/screens/home/home_screen.dart';
import 'package:protectme/models/user.dart';
import 'package:protectme/services/auth_service.dart';
import 'package:protectme/services/image_service.dart';
import 'package:protectme/services/language_service.dart';
import 'package:protectme/screens/forgot_password.dart';
import 'dart:io';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  AuthenticationScreenState createState() => AuthenticationScreenState();
}

class AuthenticationScreenState extends State<AuthenticationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  bool _isLogin = true; // Start with login mode
  bool _isLoading = false;
  bool _obscurePassword = true; // Hide password by default
  String? _profileImagePath;

  final ImageService _imageService = ImageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40),
                      if (!_isLogin) ...[
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: _profileImagePath != null
                                    ? FileImage(File(_profileImagePath!))
                                    : null,
                                backgroundColor: Colors.grey.shade200,
                                child: _profileImagePath == null
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                    onPressed: _showImagePickerDialog,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                      ] else ...[
                        Center(
                          child: Icon(
                            Icons.security,
                            size: 80,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                      Center(
                        child: Text(
                          _isLogin
                              ? context.read<LanguageService>().t('login')
                              : context.read<LanguageService>().t('signup'),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          _isLogin
                              ? context.read<LanguageService>().t('sign_in')
                              : context.read<LanguageService>().t(
                                  'create_account',
                                ),
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                      SizedBox(height: 40),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_isLogin) ...[
                              Text(
                                context.read<LanguageService>().t(
                                  'personal_info',
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: context.read<LanguageService>().t(
                                    'firstname',
                                  ),
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre nom';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: context.read<LanguageService>().t(
                                    'phone',
                                  ),
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre numéro';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 24),
                              Text(
                                context.read<LanguageService>().t(
                                  'emergency_number',
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _emergencyContactController,
                                decoration: InputDecoration(
                                  labelText: context.read<LanguageService>().t(
                                    'emergency_number',
                                  ),
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.emergency),
                                  hintText: 'Ex: 112 ou numéro d\'un proche',
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un numéro d\'urgence';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              Card(
                                color: Colors.blue.shade50,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info, color: Colors.blue),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Ce numéro sera contacté en cas d\'urgence. Assurez-vous qu\'il s\'agit d\'un numéro fiable.',
                                          style: TextStyle(
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 24),
                            ],
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: context.read<LanguageService>().t(
                                  'email',
                                ),
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre email';
                                }
                                if (!value.contains('@gmail.com')) {
                                  return 'Veuillez entrer un email valide';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: context.read<LanguageService>().t(
                                  'password',
                                ),
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe';
                                }
                                if (value.length < 8) {
                                  return 'Le mot de passe doit contenir au moins 8 caractères';
                                }
                                return null;
                              },
                            ),
                            if (_isLogin) ...[
                              SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot your password?',
                                    style: TextStyle(color: const Color.fromARGB(255, 232, 4, 228)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              if (_isLoading)
                CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  onPressed: _authenticate,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isLogin
                        ? context.read<LanguageService>().t('sign_in')
                        : context.read<LanguageService>().t('sign_up'),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? context.read<LanguageService>().t('no_account')
                        : context.read<LanguageService>().t('have_account'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    // final navigator = Navigator.of(context); // Store navigator before async
    final messenger = ScaffoldMessenger.of(
      context,
    ); // Store messenger before async

    try {
      bool success;
      if (_isLogin) {
        success = await authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Create user object for signup
        final user = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          photoUrl: _profileImagePath, // Add profile image
          birthDate: DateTime.now().subtract(
            const Duration(days: 365 * 25),
          ), // Default age 25
        );

        success = await authService.signup(user, _passwordController.text);
      }

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isLogin
                  ? context.read<LanguageService>().t('success_login')
                  : context.read<LanguageService>().t('success_signup'),
            ),
          ),
        );
        // Navigate to HomeScreen after successful authentication
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } else {
        final err = authService.lastAuthError;
        messenger.showSnackBar(
          SnackBar(
            content: Text(err ?? context.read<LanguageService>().t('error')),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }

    setState(() => _isLoading = false);
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.read<LanguageService>().t('edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text(context.read<LanguageService>().t('gallery')),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imagePath = await _imageService.pickImageFromGallery();
                  if (imagePath != null) {
                    setState(() => _profileImagePath = imagePath);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text(context.read<LanguageService>().t('camera')),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imagePath = await _imageService.takePhotoWithCamera();
                  if (imagePath != null) {
                    setState(() => _profileImagePath = imagePath);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.read<LanguageService>().t('cancel')),
            ),
          ],
        );
      },
    );
  }
}
