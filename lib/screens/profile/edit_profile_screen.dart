import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/models/user.dart';
import 'package:protectme/services/language_service.dart';
import 'package:protectme/services/auth_service.dart';
import 'package:protectme/services/image_service.dart';
import 'dart:io';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final User? user;

  const EditProfileScreen({super.key, this.user});

  @override
  // ignore: library_private_types_in_public_api
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImageService _imageService = ImageService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _medicalInfoController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _allergiesController;

  String? _profileImagePath;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _medicalInfoController = TextEditingController(
      text: widget.user?.medicalInfo ?? '',
    );
    _bloodTypeController = TextEditingController(
      text: widget.user?.bloodType ?? '',
    );
    _allergiesController = TextEditingController(
      text: widget.user?.allergies.join(', ') ?? '',
    );
    _profileImagePath = widget.user?.photoUrl;
    _birthDate = widget.user?.birthDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit profile'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _saveProfile)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImagePath != null
                          ? (_profileImagePath!.startsWith('data:')
                                ? MemoryImage(
                                    base64Decode(
                                      _profileImagePath!.split(',').last,
                                    ),
                                  )
                                : (_profileImagePath!.startsWith('http')
                                      ? NetworkImage(_profileImagePath!)
                                      : FileImage(File(_profileImagePath!))))
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      child: _profileImagePath == null
                          ? Icon(Icons.person, size: 60, color: Colors.grey)
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
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _showImagePickerDialog,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Personal Information Section
              Text(
                'Personal information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your name' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your email' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),

              // Birth Date
              InkWell(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Birth date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _birthDate != null
                        ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                        : 'Select a date',
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Medical Information Section
              Text(
                'Medical information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _medicalInfoController,
                decoration: InputDecoration(
                  labelText: 'Medical information',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _bloodTypeController,
                decoration: InputDecoration(
                  labelText: 'Blood type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype),
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'Allergies (comma separated)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change photo'),
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
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() => _birthDate = picked);
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedUser = User(
        id: widget.user?.id ?? '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: _profileImagePath,
        birthDate: _birthDate ?? DateTime.now(),
        medicalInfo: _medicalInfoController.text.trim().isEmpty
            ? null
            : _medicalInfoController.text.trim(),
        bloodType: _bloodTypeController.text.trim().isEmpty
            ? null
            : _bloodTypeController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty
            ? []
            : _allergiesController.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .toList(),
      );

      // Save to Firestore via AuthService
      final authService = context.read<AuthService>();
      authService.updateUserProfile(updatedUser).then((success) {
        if (success) {
          Navigator.of(context).pop(updatedUser);
        } else {
          // Gérer l'erreur
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving profile')));
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _medicalInfoController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }
}
